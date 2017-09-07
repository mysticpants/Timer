#require "PrettyPrinter.class.nut:1.0.1"
@include "Timer.lib.nut"

pp    <- PrettyPrinter(null, false);
print <- pp.print.bindenv(pp);



timer <- Timer();

t1 <- timer.repeat(3, function() {
    server.log("....timer 1 fired....");
});

t2 <- timer.set(15, function() {
    server.log("....timer 2 fired....");
}.bindenv(this));
