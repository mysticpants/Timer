const SCHEDULER_ACCEPTED_ERROR = 1.0;

class RepeatFromTestCase extends ImpTestCase {

    _scheduler = null;

    function setUp() {
        _scheduler = Scheduler();
    }

    function testRepeatFromPositive() {
        return _testRepeatFrom(2, 3);
    }

    function testRepeatFromDecimal() {
        return _testRepeatFrom(2, 3.2);
    }

    function testRepeatFromNow() {
        return _testRepeatFrom(0, 3);
    }

    function testRepeatFromNegative() {
        return Promise(function(resolve, reject) {
            local first = true;
            local timeToFire = time() + 1;

            local interval = -3;
            local testJob;
            testJob = _scheduler.repeatFrom(timeToFire, interval, function() {
                local firedTime = time();

                local timeError;
                if (first) {
                    timeError = firedTime - timeToFire;
                } else {
                    timeError = firedTime - timeToFire;
                }

                try {
                    this.assertTrue((timeError < SCHEDULER_ACCEPTED_ERROR && timeError > (-1 * SCHEDULER_ACCEPTED_ERROR)), "Timer fired with error of: " + timeError);

                    if (first) {
                        first = false;
                        timeToFire = time();
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

    function _testRepeatFrom(dur, interval) {
        return Promise(function(resolve, reject) {
            local first = true;
            local timeToRepeat;
            local setTime = time();

            local testJob;
            testJob = _scheduler.repeatFrom(setTime + dur, interval, function() {
                local firedTime = time();
                local timeError;
                if (first) {
                    timeError = firedTime - (setTime + dur);
                } else {
                    timeError = firedTime - timeToRepeat;
                }

                try {
                    this.assertTrue((timeError <= SCHEDULER_ACCEPTED_ERROR && timeError >= (-1 * SCHEDULER_ACCEPTED_ERROR)), "Timer fired with error of: " + timeError);

                    if (first) {
                        first = false;
                        timeToRepeat = time() + interval;
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
