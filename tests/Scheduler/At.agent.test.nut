const SCHEDULER_ACCEPTED_ERROR = 1;

class AtTestCase extends ImpTestCase {

    _scheduler = null;

    function setUp() {
        _scheduler = Scheduler();
    }

    function testAtFuture() {
        return _testAt(time() + 3);
    }

    function testAtNow() {
        return _testAt(time());
    }

    function testAtPast() {
        return Promise(function(resolve, reject) {
            local setTime = time() - 5;
            _scheduler.at(setTime, function() {
                local firedDate = date();
                local timeError = (firedDate.time - (setTime + 5)) + (firedDate.usec / 1000000.0);

                try {
                    this.assertTrue((timeError < SCHEDULER_ACCEPTED_ERROR && timeError > (-1 * SCHEDULER_ACCEPTED_ERROR)), "Timer fired with error of: " + timeError);
                    resolve();
                } catch (e) {
                    reject(e);
                }
            }.bindenv(this));
        }.bindenv(this));
    }

    function testAtWithParams() {
        return Promise(function(resolve, reject) {
            _scheduler.at(time(), function(testInt) {
                try {
                    this.assertTrue(testInt == 5, "Parameter not passed correctly to callback");
                    resolve();
                } catch (e) {
                    reject(e);
                }
            }.bindenv(this), 5);
        }.bindenv(this));
    }

    function _testAt(setTime) {
        return Promise(function(resolve, reject) {
            _scheduler.at(setTime, function() {
                try {
                    if (typeof setTime == "string") {
                        setTime = _scheduler._strToDate(setTime);
                        this.info("FINISH THIS");
                    }
                    local firedDate = date();
                    local timeError = (firedDate.time - setTime) + (firedDate.usec / 1000000.0);
                    this.assertTrue((timeError < SCHEDULER_ACCEPTED_ERROR && timeError > (-1 * SCHEDULER_ACCEPTED_ERROR)), "Timer fired with error of: " + timeError);
                    resolve();
                } catch (e) {
                    reject(e);
                }
            }.bindenv(this));
        }.bindenv(this));
    }

}
