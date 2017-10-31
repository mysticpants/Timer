const JOB_TYPE_SET         = "set";
const JOB_TYPE_AT          = "at";
const JOB_TYPE_REPEAT      = "repeat";
const JOB_TYPE_REPEAT_FROM = "repeat from";

const JOB_ERROR_RESET = "Cannot reset job type: %s";

class Scheduler {

    static VERSION = "1.0.0";

    _jobs       = [];
    _currentJob = null;
    _currentId  = null;
    _nextId     = 1;

    // Start a new timer to trigger after a specific duration
    //
    // Parameters:
    //     dur (float)       the duration of the timer
    //     cb  (function)    the function to run when the timer fires
    // Return: (integer) the id number of the timer (can be used to cancel the timer)
    function set(dur, cb, ...) {
        local now = date();
        vargv.insert(0, null);

        if (dur < 0) dur = 0;

        local newJob = Job(this, {
            "type": JOB_TYPE_SET,
            "id": _nextId++,
            "dur": dur,
            "sec": math.floor(dur).tointeger() + now.time,
            "subSec": dur - math.floor(dur).tointeger() + (now.usec / 1000000.0),
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
        vargv.insert(0, null);

        if (t < now.time) t = now.time;

        local newJob = Job(this, {
            "type": JOB_TYPE_AT,
            "id": _nextId++,
            "sec": (typeof t == "string") ? (_strtodate(t, tzoffset()).time) : t,
            "subSec": 0.0,
            "cb": cb,
            "args": vargv
        });
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
            local now = date();
            vargv.insert(0, null);

            if (int < 0) int = 0;

            local newJob = Job(this, {
                "type": JOB_TYPE_REPEAT,
                "id": _nextId++,
                "sec": math.floor(int).tointeger() + now.time,
                "subSec": int - math.floor(int).tointeger() + (now.usec / 1000000.0),
                "repeat": int,
                "cb": cb,
                "args": vargv
            });
            _addJob(newJob);

            return newJob;
        } catch(e) {
            server.error("naesiudf;nkdjksa");
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
        vargv.insert(0, null);

        if (int < 0) int = 0;
        if (t < now.time) t = now.time;

        local newJob = Job(this, {
            "type": JOB_TYPE_REPEAT_FROM,
            "id": _nextId++,
            "sec": (typeof t == "string") ? (_strtodate(t, tzoffset()).time) : t,
            "subSec": 0.0,
            "repeat": int,
            "cb": cb,
            "args": vargv
        });
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

            local now = date();
            local dur = (_jobs[0].sec - now.time) + (_jobs[0].subSec - now.usec / 1000000.0);

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

    function _strToDate(str, tz=0) {

        // Prepare the variables
        local year, month, day, hour, min, sec;

        // Capture the components of the date time string
        local ex = regexp(@"([a-zA-Z]+) ([0-9]+), ([0-9]+) ([0-9]+):([0-9]+) ([AP]M)");
        local ca = ex.capture(str);
        if (ca != null) {
            year = str.slice(ca[3].begin, ca[3].end).tointeger();
            month = str.slice(ca[1].begin, ca[1].end);
            switch (month) {
                case "January": month = 0; break;  case "February": month = 1; break;  case "March": month = 2; break;
                case "April": month = 3; break;    case "May": month = 4; break;       case "June": month = 5; break;
                case "July": month = 6; break;     case "August": month = 7; break;    case "September": month = 8; break;
                case "October": month = 9; break;  case "November": month = 10; break; case "December": month = 11; break;
                default: throw "Invalid month";
            }
            day = str.slice(ca[2].begin, ca[2].end).tointeger()-1;
            hour = str.slice(ca[4].begin, ca[4].end).tointeger();
            min = str.slice(ca[5].begin, ca[5].end).tointeger();
            sec = 0;

            // Tweak the 12-hour clock
            if (hour == 12) hour = 0;
            if (str.slice(ca[6].begin, ca[6].end) == "PM") hour += 12;

        } else {
            ex = regexp(@"([0-9]+):([0-9]+)(:([0-9]+))?");
            ca = ex.capture(str);
            if (ca.len() == 5) {
                local local_now = date(time() + tz);
                year = local_now.year;
                month = local_now.month;
                day = local_now.day-1;
                hour = str.slice(ca[1].begin, ca[1].end).tointeger();
                min = str.slice(ca[2].begin, ca[2].end).tointeger();
                if (ca[4].begin == ca[4].end) sec = 0;
                else sec = str.slice(ca[4].begin, ca[4].end).tointeger();

                // Tweak the 24 hour clock
                if (hour*60*60 + min*60 + sec < local_now.hour*60*60 + local_now.min*60 + local_now.sec) {
                    hour += 24;
                }

                // Adjust back to UTC
                tz = -tz;

            } else {
                throw "We are currently expecting, exactly, this format: 'Tuesday, January 7, 2014 9:57 AM'";
            }
        }

        // Do some bounds checking now
        if (year < 2012 || year > 2017) throw "Only 2012 to 2017 is currently supported";

        // Work out how many seconds since January 1st
        local epoch_offset = { "2012":1325376000, "2013":1356998400, "2014":1388534400, "2015":1420070400, "2016":1451606400, "2017":1483228800 };
        local seconds_per_month = [ 2678400, 2419200, 2678400, 2592000, 2678400, 2592000, 2678400, 2678400, 2592000, 2678400, 2592000, 2678400];
        local leap = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
        if (leap) seconds_per_month[1] = 2505600;

        local offset = epoch_offset[year.tostring()];
        for (local m = 0; m < month; m++) offset += seconds_per_month[m];
        offset += (day * 86400);
        offset += (hour * 3600);
        offset += (min * 60);
        offset += sec;
        offset += tz;

        // Finally, generate a date object from the offset
        local dateobj = date(offset);
        dateobj.str <- format("%02d-%02d-%02d %02d:%02d:%02d Z", dateobj.year, dateobj.month+1, dateobj.day, dateobj.hour, dateobj.min, dateobj.sec);
        return dateobj;
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
        local now = date();

        postPauseDur = (sec - now.time) + (subSec - now.usec / 1000000.0);

        _scheduler._cancel(id);

        return this;
    }

    // Unpause the timer for this job.
    //
    // Return: (Job) this
    function unpause() {
        local now = date();

        sec = math.floor(postPauseDur).tointeger() + now.time;
        subSec = postPauseDur - math.floor(postPauseDur).tointeger() + (now.usec / 1000000.0);

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

        local now = date();

        // Find the duration to reset the timer with
        if (rstDur == null) {
            if ("dur" in this) {
                rstDur = dur;
            } else if ("repeat" in this) {
                rstDur = repeat;
            }
        }

        sec = math.floor(rstDur).tointeger() + now.time;
        subSec = rstDur - math.floor(rstDur).tointeger() + (now.usec / 1000000.0);

        _scheduler._cancel(id);
        _scheduler._addJob(this);

        return this;
    }

}
