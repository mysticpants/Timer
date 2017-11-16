@include "Scheduler.lib.nut"

timer <- Scheduler();

server.log("start...");

start <- date();
t1 <- timer.at(time() + 3.5, function() {
    local end = date();
    server.log((end.time - start.time) + (end.usec / 1000000.0 - start.usec / 1000000.0));
    start = end;
}.bindenv(this));
