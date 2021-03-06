const SCHEDULER_ACCEPTED_ERROR = 0.1;

class RepeatTestCase extends ImpTestCase {

    _scheduler = null;

    function setUp() {
        _scheduler = Scheduler();
    }

    function testRepeatPositive() {
        return _testRepeat(3);
    }

    function testRepeatDecimal() {
        return _testRepeat(3.2);
    }

    function testRepeatNegative() {
        return Promise(function(resolve, reject) {
            local first = true;
            local setTime = date();

            local interval = -3;
            local testJob;
            testJob = _scheduler.repeat(interval, function() {
                local firedTime = date();
                local timeError = ((firedTime.time - setTime.time) + (firedTime.usec - setTime.usec) / 1000000.0);

                try {
                    this.assertTrue((timeError < SCHEDULER_ACCEPTED_ERROR && timeError > (-1 * SCHEDULER_ACCEPTED_ERROR)), "Timer fired with error of: " + timeError);

                    if (first) {
                        first = false;
                    } else {
                        testJob.cancel();
                        resolve();
                    }
                } catch (e) {
                    reject(e);
                }
            }.bindenv(this));
        }.bindenv(this));
    }

    function testRepeatWithParams() {
        return Promise(function(resolve, reject) {
            local job1 = null;
            job1 = _scheduler.repeat(0, function(testInt) {
                try {
                    this.assertTrue(testInt == 5, "Parameter not passed correctly to callback");
                    resolve();
                } catch (e) {
                    reject(e);
                }
                job1.cancel();
            }.bindenv(this), 5);
        }.bindenv(this));
    }

    function _testRepeat(interval) {
        return Promise(function(resolve, reject) {
            local first = true;
            local setTime = date();

            local testJob;
            testJob = _scheduler.repeat(interval, function() {
                local firedTime = date();
                local timeError = ((firedTime.time - setTime.time) + (firedTime.usec - setTime.usec) / 1000000.0) - interval;

                try {
                    this.assertTrue((timeError < SCHEDULER_ACCEPTED_ERROR && timeError > (-1 * SCHEDULER_ACCEPTED_ERROR)), "Timer fired with error of: " + timeError);

                    if (first) {
                        first = false;
                        setTime.time += math.floor(interval).tointeger();
                        setTime.usec += (interval - math.floor(interval).tointeger()) * 1000000;
                    } else {
                        testJob.cancel();
                        resolve();
                    }
                } catch (e) {
                    reject(e);
                }
            }.bindenv(this));
        }.bindenv(this));
    }

}
