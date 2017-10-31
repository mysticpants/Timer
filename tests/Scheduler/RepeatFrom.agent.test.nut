const SCHEDULER_ACCEPTED_ERROR = 1.0;

class RepeatFromTestCase extends ImpTestCase {

    _scheduler = null;

    function setUp() {
        _scheduler = Scheduler();
    }

    function testRepeatFromPositive() {
        return _testRepeatFrom(time() + 2, 3);
    }

    function testRepeatFromDecimal() {
        return _testRepeatFrom(time() + 2, 3.2);
    }

    function testRepeatFromNow() {
        return _testRepeatFrom(time(), 3);
    }

    function testRepeatFromNegative() {
        return Promise(function(resolve, reject) {
            local first = true;
            local setTime = date();

            local interval = -3;
            local testJob;
            testJob = _scheduler.repeatFrom(time() + 1, interval, function() {
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

    function testRepeatFromWithParams() {
        return Promise(function(resolve, reject) {
            local job1 = null;
            job1 = _scheduler.repeatFrom(time(), 0, function(testInt) {
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

    function _testRepeatFrom(timeToFire, interval) {
        return Promise(function(resolve, reject) {
            local first = true;
            local setDate;

            local testJob;
            testJob = _scheduler.repeatFrom(timeToFire, interval, function() {
                local firedDate = date();
                local timeError;
                if (first) {
                    timeError = firedDate.time - timeToFire;
                } else {
                    timeError = ((firedDate.time - setDate.time) + (firedDate.usec - setDate.usec) / 1000000.0) - interval;
                }

                try {
                    this.assertTrue((timeError <= SCHEDULER_ACCEPTED_ERROR && timeError >= (-1 * SCHEDULER_ACCEPTED_ERROR)), "Timer fired with error of: " + timeError);

                    if (first) {
                        first = false;
                        setDate = date();
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
