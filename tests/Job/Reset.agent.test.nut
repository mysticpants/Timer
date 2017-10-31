class ResetTestCase extends ImpTestCase {

    _scheduler = null;

    function setUp() {
        _scheduler = Scheduler();
    }

    function testReset() {
        local dur = 5;
        local fired = false;
        local job1 = _scheduler.set(dur, function() {fired = true;}.bindenv(this));

        return Promise(function(resolve,reject) {
            imp.wakeup(dur - 2, function() {
                job1.reset();
            }.bindenv(this));

            try {
                imp.wakeup(dur + 2, function() {
                    this.assertTrue(!fired, "Job fired despite being reset");
                    imp.wakeup(dur, function() {
                        this.assertTrue(fired, "Job didn't fire after being reset");
                        resolve();
                    }.bindenv(this));
                }.bindenv(this));
            } catch(e) {
                reject(e);
            }

        }.bindenv(this));
    }

}
