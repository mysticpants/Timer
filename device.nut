@include "Scheduler.lib.nut"

timer <- Scheduler();

server.log("start...");

start <- hardware.millis() / 1000.0;
t1 <- timer.at(time() + 3, function() {
    local end = hardware.millis() / 1000.0;
    server.log(end - start);
    start = end;
}.bindenv(this));
