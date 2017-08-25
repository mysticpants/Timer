/*............./[ Samples ]\..................
t <- Timer().set(10, function() {
     // Do something in 10 seconds
});
t <- Timer().repeat(10, function() {
     // Do something every 10 seconds
}).now();
t.cancel();

Timer.tzoffset(-25200);
Timer().daily("11:00", function() {
    // Do something every 11am in UTC-7
});
............./[ Samples ]\..................*/
