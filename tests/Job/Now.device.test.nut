class NowTestCase extends ImpTestCase {

    _scheduler = null;

    function setUp() {
        _scheduler = Scheduler();
    }

    function testNow() {
        return Promise(function(resolve, reject) {
            local dur = 5;
            local job1 = _scheduler.set(dur, function() {
                resolve();
            }.bindenv(this));

            job1.now();

            reject("Job did not fire when Job.now() was called");
        }.bindenv(this));
    }

}
