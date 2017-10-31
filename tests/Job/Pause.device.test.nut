class PauseAndUnpauseTestCase extends ImpTestCase {

    _scheduler = null;

    function setUp() {
        _scheduler = Scheduler();
    }

    function testPauseAndUnpause() {
        local dur = 3;
        local fired = false;
        local job1 = _scheduler.set(dur, function() {fired = true;}.bindenv(this));

        return Promise(function(resolve,reject) {
            job1.pause();

            try {
                imp.wakeup(dur + 2, function() {
                    this.assertTrue(!fired, "Job fired despite being paused");
                    job1.unpause();
                    imp.wakeup(dur + 2, function() {
                        this.assertTrue(fired, "Job didn't fire despite being unpaused");
                        resolve();
                    }.bindenv(this));
                }.bindenv(this));
            } catch(e) {
                reject(e);
            }

        }.bindenv(this));
    }

}
