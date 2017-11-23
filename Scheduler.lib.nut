//MIT License
//
//Copyright 2017 Mystic Pants
//
//SPDX-License-Identifier: MIT
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be
//included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
//EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
//OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
//ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//OTHER DEALINGS IN THE SOFTWARE.

const JOB_TYPE_SET         = "set";
const JOB_TYPE_AT          = "at";
const JOB_TYPE_REPEAT      = "repeat";
const JOB_TYPE_REPEAT_FROM = "repeat from";

const JOB_ERROR_RESET = "Cannot reset job type: %s";

class Scheduler {

    static VERSION = "1.0.0";

    _env = null;

    _jobs       = [];
    _currentJob = null;
    _currentId  = null;
    _nextId     = 1;

    constructor() {
        _env = imp.environment();
    }

    // Start a new timer to trigger after a specific duration
    //
    // Parameters:
    //     dur (float)       the duration of the timer
    //     cb  (function)    the function to run when the timer fires
    // Return: (integer) the id number of the timer (can be used to cancel the timer)
    function set(dur, cb, ...) {
        local now = _getTime();
        vargv.insert(0, null);

        if (dur < 0) dur = 0;

        local newJob = Job(this, {
            "type": JOB_TYPE_SET,
            "id": _nextId++,
            "dur": dur,
            "sec": _getSec(dur, now),
            "subSec": _getSubSec(dur, now),
            "cb": cb,
            "args": vargv
        });
        _addJob(newJob);

        return newJob;
    }

    // Start a new timer to trigger at a specific time
    //
    // Parameters:
    //     t  (float)       the time that the timer should fire
    //     cb (function)    the function to run when the timer fires
    // Return: (integer) the id number of the timer (can be used to cancel the timer)
    function at(t, cb, ...) {
        local now = date();
        local nowMillis = null;
        if (_env != ENVIRONMENT_AGENT) nowMillis = hardware.millis() / 1000.0;

        vargv.insert(0, null);

        if (t < now.time) t = now.time;

        local newJob = Job(this, {
            "type": JOB_TYPE_AT,
            "id": _nextId++,
            "cb": cb,
            "args": vargv
        });

        if (_env == ENVIRONMENT_AGENT) {
            newJob.sec = t;
            newJob.subSec = 0.0;
        } else {
            newJob.sec = math.floor(nowMillis).tointeger() + (t - now.time);
            newJob.subSec = nowMillis - math.floor(nowMillis).tointeger();
        }

        _addJob(newJob);

        return newJob;
    }

    // Start a new timer to trigger repeatedly at a specific interval
    //
    // Parameters:
    //     int (float)     the time between executions of the timer
    //     cb  (function)    the function to run when the timer fires
    // Return: (integer) the id number of the timer (can be used to cancel the timer)
    function repeat(int, cb, ...) {
        try {
            local now = _getTime();
            vargv.insert(0, null);

            if (int < 0) int = 0;

            local newJob = Job(this, {
                "type": JOB_TYPE_REPEAT,
                "id": _nextId++,
                "sec": _getSec(int, now),
                "subSec": _getSubSec(int, now),
                "repeat": int,
                "cb": cb,
                "args": vargv
            });
            _addJob(newJob);

            return newJob;
        } catch(e) {
            server.error(e);
            throw e;
        }
    }

    // Start a new timer to trigger repeatedly at a specific interval, starting at a specific time
    //
    // Parameters:
    //     t   (float)     the time for the first execution of the timer
    //     int (float)     the time between executions of the timer
    //     cb  (function)    the function to run when the timer fires
    // Return: (integer) the id number of the timer (can be used to cancel the timer)
    function repeatFrom(t, int, cb, ...) {
        local now = date();
        local nowMillis = null;
        if (_env != ENVIRONMENT_AGENT) nowMillis = hardware.millis() / 1000.0;

        vargv.insert(0, null);

        if (int < 0) int = 0;
        if (t < now.time) t = now.time;

        local newJob = Job(this, {
            "type": JOB_TYPE_REPEAT_FROM,
            "id": _nextId++,
            "repeat": int,
            "cb": cb,
            "args": vargv
        });

        if (_env == ENVIRONMENT_AGENT) {
            newJob.sec = t;
            newJob.subSec = 0.0;
        } else {
            newJob.sec = math.floor(nowMillis).tointeger() + (t - now.time);
            newJob.subSec = nowMillis - math.floor(nowMillis).tointeger();
        }

        _addJob(newJob);

        return newJob;
    }

    function tzoffset(offset = null) {
        // Store and retrieve the tzoffset from the global scope
        if (!("timer_tzoffset" in ::getroottable())) ::timer_tzoffset <- 0;
        if (offset != null) ::timer_tzoffset <- offset;
        return ::timer_tzoffset;
    }

    // -------------------- PRIVATE METHODS -------------------- //

    // Add a new timer into the correct position in the _jobs array
    //
    // Parameters:
    //     newJob (table)       a table representing the new timer
    function _addJob(newJob) {
        if (_jobs.len() == 0) {
            _jobs.insert(0, newJob);
            _start();
            return;
        }

        for (local i = _jobs.len() - 1; i >= 0; i--) {
            if ((_jobs[i].sec < newJob.sec) || (_jobs[i].sec == newJob.sec && _jobs[i].subSec < newJob.subSec)) {
                _jobs.insert(i + 1, newJob);
                break;
            } else if (i == 0) {
                _jobs.insert(0, newJob);
                _start();
                break;
            }
        }
    }

    function _next() {
        if(_currentJob != null) {
            imp.cancelwakeup(_currentJob);
            _currentJob = null;
            _currentId = null;
        }

        if (_jobs.len() >= 1) {
            // If the current timer needs to repeat it should be added back into the array
            if ("repeat" in _jobs[0] && _jobs[0].repeat != null) {
                local tmpJob = _jobs[0];
                _jobs.remove(0);
                tmpJob.sec += math.floor(tmpJob.repeat).tointeger();
                tmpJob.subSec += tmpJob.repeat - math.floor(tmpJob.repeat).tointeger();

                // Change type from JOB_TYPE_REPEAT_FROM to JOB_TYPE_REPEAT (important for resetting)
                if (tmpJob.type == JOB_TYPE_REPEAT_FROM) tmpJob.type = JOB_TYPE_REPEAT;

                _addJob(tmpJob);
            } else {
                _jobs.remove(0);
            }
        }

        _start();
    }

    function _start() {
        if (_jobs.len() > 0) {
            if (_currentJob != null) imp.cancelwakeup(_currentJob);

            local dur = _getDur(_jobs[0]);

            _currentJob = imp.wakeup(dur, function() {
                _jobs[0].cb.acall(_jobs[0].args);
                _next();
            }.bindenv(this));
            _currentId = _jobs[0].id;
        }
    }

    // Cancel an existing timer
    //
    // Parameters:
    //     id (integer)       the id of the existing timer
    // Return: (boolean) whether the timer was removed or not
    function _cancel(id) {
        // If the timer to cancel is currently running, cancel it
        if (_currentId == id) {
            imp.cancelwakeup(_currentJob);
            _currentJob = null;
            _currentId = null;
        }

        // Look for the timer in the queue and remove it
        foreach (i, t in _jobs) {
            if (_jobs[i].id == id) {
                _jobs.remove(i);
                // Check if the timer to cancel is at the front of the queue
                if (i == 0 && _jobs.len() >= 1) {
                    _next();
                }
            }
        }
    }

    // Trigger an existing timer's callback to run now (timer will also continue as normal)
    //
    // Parameters:
    //     id (integer)       the id of the existing timer
    // Return: (boolean) whether the callback was triggered or not
    function _now(id) {
        foreach (i, t in _jobs) {
            if (_jobs[i].id == id) {
                _jobs[i].cb.acall(_jobs[i].args);
            }
        }
    }

    // Get the current time differently on device and agent
    function _getTime() {
        if (_env == ENVIRONMENT_AGENT) return date();
        else                           return hardware.millis() / 1000.0;
    }

    // Calculate "second" count for a timer differently on device and agent
    function _getSec(dur, now) {
        if (_env == ENVIRONMENT_AGENT) return math.floor(dur).tointeger() + now.time;
        else                           return math.floor(dur).tointeger() + math.floor(now).tointeger();
    }

    // Calculate "sub second" count for a timer differently on device and agent
    function _getSubSec(dur, now) {
        if (_env == ENVIRONMENT_AGENT) return dur - math.floor(dur).tointeger() + (now.usec / 1000000.0);
        else                           return dur - math.floor(dur).tointeger() + (now - math.floor(now).tointeger());
    }

    function _getDur(job) {
        if (_env == ENVIRONMENT_AGENT) {
            local now = date();
            return (job.sec - now.time) + (job.subSec - now.usec / 1000000.0);
        } else {
            local now = hardware.millis() / 1000.0;
            local nowSec = math.floor(now).tointeger();
            local nowSubSec = (now) - math.floor(now).tointeger();

            return (job.sec - nowSec) + (job.subSec - nowSubSec);
        }
    }

}

class Job {

    _scheduler = null;

    type   = null;
    id     = null;
    dur    = null;
    sec    = null;
    subSec = null;
    repeat = null;
    cb     = null;
    args   = null;

    postPauseDur = null;

    constructor(scheduler, params) {
        try {
        _scheduler = scheduler;

        if ("type" in params)   type   = params.type;
        if ("id" in params)     id     = params.id;
        if ("dur" in params)    dur    = params.dur;
        if ("sec" in params)    sec    = params.sec;
        if ("subSec" in params) subSec = params.subSec;
        if ("repeat" in params) repeat = params.repeat;
        if ("cb" in params)     cb     = params.cb;
        if ("args" in params)   args   = params.args;

        return this;
        } catch (e) {
            server.error("adfsln ");
            server.error(e);
            throw e;
        }
    }

    // Cancel this job.
    //
    // Return: (Job) this
    function cancel() {
        _scheduler._cancel(id);

        return this;
    }

    // Trigger this job to fire immediately.
    //
    // Return: (Job) this
    function now() {
        _scheduler._now(id);

        return this;
    }

    // Pause the timer for this job.
    //
    // Return: (Job) this
    function pause() {
        postPauseDur = _scheduler._getDur({"sec": sec, "subSec": subSec});

        _scheduler._cancel(id);

        return this;
    }

    // Unpause the timer for this job.
    //
    // Return: (Job) this
    function unpause() {
        local now = _scheduler._getTime();

        sec = _scheduler._getSec(postPauseDur, now);
        subSec = _scheduler._getSubSec(postPauseDur, now);

        postPauseDur = null;

        _scheduler._addJob(this);

        return this;
    }

    // Reset the timer for this job to start again. Doesn't work for "at" jobs or first execution of "repeat_from" jobs.
    //
    // Parameters:
    //     rstDur (float) [null]       The optional new duration of the job's timer. Will default to the original duration
    // Return: (Job) this
    function reset(rstDur=null) {
        if ([JOB_TYPE_AT, JOB_TYPE_REPEAT_FROM].find(type) != null) throw format(JOB_ERROR_RESET, type);

        local now = _scheduler._getTime();

        // Find the duration to reset the timer with
        if (rstDur == null) {
            if ("dur" in this) {
                rstDur = dur;
            } else if ("repeat" in this) {
                rstDur = repeat;
            }
        }

        sec = _scheduler._getSec(rstDur, now);
        subSec = _scheduler._getSubSec(rstDur, now);

        _scheduler._cancel(id);
        _scheduler._addJob(this);

        return this;
    }

}
