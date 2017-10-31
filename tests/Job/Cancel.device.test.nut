class CancelTestCase extends ImpTestCase {

    _scheduler = null;

    function setUp() {
        _scheduler = Scheduler();
    }

    function testCancel() {
        return Promise(function(resolve, reject) {
            local dur = 3;
            // Reject if the callback fires
            local job1 = _scheduler.set(dur, function() {
                reject("Job fired even though it was cancelled");
            }.bindenv(this));
            
            job1.cancel();

            // Timeout to resolve if callback hasn't fired
            imp.wakeup(dur + 2, function() {
                resolve();
            }.bindenv(this));
        }.bindenv(this));
    }

}
