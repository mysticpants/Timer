class Timer {

    static VERSION = "1.0.0";

    _nextId = 1;
    _timers = [];
    _currentTimer = null;

    constructor() {

    }

    // Start a new timer to trigger after a specific duration
    //
    // Parameters:
    //     dur (float)       the duration of the timer
    //     cb  (function)    the function to run when the timer fires
    // Return: (integer) the id number of the timer (can be used to cancel the timer)
    function set(dur, cb, ...) {
        local now = date();
        vargv.insert(0, this);
        _addTimer({
            "id": _nextId,
            "sec": math.floor(dur).tointeger() + now.time,
            "subSec": dur - math.floor(dur).tointeger() + (now.usec / 1000000.0),
            "cb": cb,
            "args": vargv
        });
        return _nextId++;
    }

    // Start a new timer to trigger at a specific time
    //
    // Parameters:
    //     t  (float)       the time that the timer should fire
    //     cb (function)    the function to run when the timer fires
    // Return: (integer) the id number of the timer (can be used to cancel the timer)
    function at(t, cb, ...) {
        vargv.insert(0, this);
        _addTimer({
            "id": _nextId,
            "sec": (typeof t == "string") ? (_strtodate(t, tzoffset()).time) : t,
            "subSec": 0.0,
            "cb": cb,
            "args": vargv
        });
        return _nextId++;
    }

    // Start a new timer to trigger repeatedly at a specific interval
    //
    // Parameters:
    //     int (float)     the time between executions of the timer
    //     cb  (function)    the function to run when the timer fires
    // Return: (integer) the id number of the timer (can be used to cancel the timer)
    function repeat(int, cb, ...) {
        local now = date();
        vargv.insert(0, this);
        _addTimer({
            "id": _nextId,
            "sec": math.floor(int).tointeger() + now.time,
            "subSec": int - math.floor(int).tointeger() + (now.usec / 1000000.0),
            "repeat": int,
            "cb": cb,
            "args": vargv
        });
        return _nextId++;
    }

    // Start a new timer to trigger repeatedly at a specific interval, starting at a specific time
    //
    // Parameters:
    //     t   (float)     the time for the first execution of the timer
    //     int (float)     the time between executions of the timer
    //     cb  (function)    the function to run when the timer fires
    // Return: (integer) the id number of the timer (can be used to cancel the timer)
    function repeatFrom(t, int, cb, ...) {
        vargv.insert(0, this);
        _addTimer({
            "id": _nextId,
            "sec": (typeof t == "string") ? (_strtodate(t, tzoffset()).time) : t,
            "subSec": 0.0,
            "repeat": int,
            "cb": cb,
            "args": vargv
        });
        return _nextId++;
    }

    // Cancel an existing timer
    //
    // Parameters:
    //     id (integer)       the id of the existing timer
    // Return: (boolean) whether the timer was removed or not
    function cancel(id) {
        foreach (i, t in _timers) {
            if (_timers[i].id == id) {
                // Check if the timer to cancel is at the front of the queue
                if (i == 0) {
                    _next();
                } else {
                    _timers.remove(i);
                }
                return true;
            }
        }
        return false;
    }

    // Trigger an existing timer's callback to run now (timer will also continue as normal)
    //
    // Parameters:
    //     id (integer)       the id of the existing timer
    // Return: (boolean) whether the callback was triggered or not
    function now(id) {
        foreach (i, t in _timers) {
            if (_timers[i].id == id) {
                _timers[i].cb.acall(_timers[i].args);
                return true;
            }
        }
        return false;
    }

    function tzoffset(offset = null) {
        // Store and retrieve the tzoffset from the global scope
        if (!("timer_tzoffset" in ::getroottable())) ::timer_tzoffset <- 0;
        if (offset != null) ::timer_tzoffset <- offset;
        return ::timer_tzoffset;
    }

    // -------------------- PRIVATE METHODS -------------------- //

    // Add a new timer into the correct position in the _timers array
    //
    // Parameters:
    //     newTimer (table)       a table representing the new timer
    function _addTimer(newTimer) {
        if (_timers.len() == 0) {
            _timers.insert(0, newTimer);
            _start();
            return;
        }

        for (local i = _timers.len() - 1; i >= 0; i--) {
            if ((_timers[i].sec < newTimer.sec) || (_timers[i].sec == newTimer.sec && _timers[i].subSec < newTimer.subSec)) {
                _timers.insert(i + 1, newTimer);
                break;
            } else if (i == 0) {
                _timers.insert(0, newTimer);
                _start();
                break;
            }
        }
    }

    function _next() {
        imp.cancelwakeup(_currentTimer);
        _currentTimer = null;
        // If the current timer needs to repeat it should be added back into the array
        if ("repeat" in _timers[0] && _timers[0].repeat != null) {
            local tmpTimer = _timers[0];
            _timers.remove(0);
            tmpTimer.sec += math.floor(tmpTimer.repeat).tointeger();
            tmpTimer.subSec += tmpTimer.repeat - math.floor(tmpTimer.repeat).tointeger();
            _addTimer(tmpTimer);
        } else {
            _timers.remove(0);
        }
        _start();
    }

    function _start() {
        if (_timers.len() > 0) {
            if (_currentTimer != null) imp.cancelwakeup(_currentTimer);

            local now = date();
            local dur = (_timers[0].sec - now.time) + (_timers[0].subSec - now.usec / 1000000.0);

            _currentTimer = imp.wakeup(dur, function() {
                _timers[0].cb.acall(_timers[0].args);
                _next();
            }.bindenv(this));
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
