const SCHEDULER_ACCEPTED_ERROR = 0.1;

class SetTestCase extends ImpTestCase {

    _scheduler = null;

    function setUp() {
        _scheduler = Scheduler();
    }

    function testSetPositive() {
        return _testSet(3);
    }

    function testSetZero() {
        return _testSet(0);
    }

    function testSetDecimal() {
        return _testSet(3.5);
    }

    function testSetNegative() {
        return Promise(function(resolve, reject) {
            local dur = -5;
            local setTime = hardware.millis() / 1000.0;

            _scheduler.set(dur, function() {
                local firedTime = hardware.millis() / 1000.0;
                local timeError = (firedTime - setTime);

                try {
                    this.assertTrue((timeError < SCHEDULER_ACCEPTED_ERROR && timeError > (-1 * SCHEDULER_ACCEPTED_ERROR)), "Timer fired with error of: " + timeError);
                    resolve();
                } catch (e) {
                    reject(e);
                }
            }.bindenv(this));
        }.bindenv(this));
    }

    function testSetWithParams() {
        return Promise(function(resolve, reject) {
            _scheduler.set(0, function(testInt) {
                try {
                    this.assertTrue(testInt == 5, "Parameter not passed correctly to callback");
                    resolve();
                } catch (e) {
                    reject(e);
                }
            }.bindenv(this), 5);
        }.bindenv(this));
    }

    function _testSet(dur) {
        return Promise(function(resolve, reject) {
            local setTime = hardware.millis() / 1000.0;

            _scheduler.set(dur, function() {
                local firedTime = hardware.millis() / 1000.0;
                local timeError = (firedTime - setTime) - dur;

                try {
                    this.assertTrue((timeError < SCHEDULER_ACCEPTED_ERROR && timeError > (-1 * SCHEDULER_ACCEPTED_ERROR)), "Timer fired with error of: " + timeError);
                    resolve();
                } catch (e) {
                    reject(e);
                }
            }.bindenv(this));
        }.bindenv(this));
    }

}
