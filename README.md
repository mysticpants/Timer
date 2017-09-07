# Timer

A simple class to manage timers with one-off and interval timers all of which can be cancelled.
Can be used to create multiple timers that actually share a single timer which may be helpful on
the agent where the number of active timers is limited.

To add this library to your model, add the following lines to
the top of your agent code:

```
#require "Timer.class.nut:1.0.0"
```

## Class Usage

### constructor(\_params, \_send\_self)
Timer object constructor which takes the following parameters:

Parameter         | Type           | Required       | Default        | Description
----------------- | -------------- | -------------- | -------------- | ----------------
\_params          | ANY            | No             | null           | A value to pass to the callback when it is called
\_send\_self      | boolean        | No             | false          | If set to true, a reference to the timer object will be passed to the callback

#### Example

```squirrel
// initialise the class
t <- Timer({ "id": 1 }, true);
```

## Class Methods

### tzoffset(offset)
Set the offset for the timezone.

Parameter         | Type           | Required       | Default        | Description
----------------- | -------------- | -------------- | -------------- | ----------------
offset            | integer        | No             | null           | The time offset in hours

### update(\_params)
Update the object's parameters that were set in the constructor.

Parameter         | Type           | Required       | Default        | Description
----------------- | -------------- | -------------- | -------------- | ----------------
\_params          | string         | Yes            | N/A            | A value to pass to the callback when it is called

### set(\_duration, \_callback)
Start a new timer to execute the callback after the specified duration.

Parameter         | Type           | Required       | Default        | Description
----------------- | -------------- | -------------- | -------------- | ----------------
\_duration        | float          | Yes            | N/A            | The duration of the timer in seconds
\_callback        | function       | Yes            | N/A            | The function to run when the timer finishes

#### Example

```squirrel
function myFunc(timer, params) {
    server.log("id: " + params.id);
}
t <- Timer({ "id": 1 }, true).set(5, myFunc);
// Will print to the logs: "id: 1"
```

### repeat(\_interval, \_callback)
Start a new timer to repeat the execution of the callback at the specified interval.

Parameter         | Type           | Required       | Default        | Description
----------------- | -------------- | -------------- | -------------- | ----------------
\_interval        | float          | Yes            | N/A            | The interval between executions of the timer in seconds
\_callback        | function       | Yes            | N/A            | The function to run when the timer finishes

### now()
Immediately execute a callback that has already been set with set/repeat.

### at(\_time, \_callback)
Start a new timer to execute the callback at the specified time. The time can either be provided as an integer
representing the number of seconds that have elapsed since midnight on 1 January 1970 OR as a string in the following
format: "January 01, 2017 12:30 PM".

Parameter         | Type           | Required       | Default        | Description
----------------- | -------------- | -------------- | -------------- | ----------------
\_time            | integer/string | Yes            | N/A            | The time when the timer should end
\_callback        | function       | Yes            | N/A            | The function to run when the timer finishes

### daily(\_time, \_callback)
Start a new timer to execute the callback at the specified time and then at the same time everyday after that.

Parameter         | Type           | Required       | Default        | Description
----------------- | -------------- | -------------- | -------------- | ----------------
\_time            | integer/string | Yes            | N/A            | The time when the timer should end
\_callback        | function       | Yes            | N/A            | The function to run when the timer finishes

### hourly(\_time, \_callback)
Start a new timer to execute the callback at the specified time and then every hour after that.

Parameter         | Type           | Required       | Default        | Description
----------------- | -------------- | -------------- | -------------- | ----------------
\_time            | integer/string | Yes            | N/A            | The time when the timer should end
\_callback        | function       | Yes            | N/A            | The function to run when the timer finishes

### minutely(\_time, \_callback)
Start a new timer to execute the callback at the specified time and then every minute after that.

Parameter         | Type           | Required       | Default        | Description
----------------- | -------------- | -------------- | -------------- | ----------------
\_time            | integer/string | Yes            | N/A            | The time when the timer should end
\_callback        | function       | Yes            | N/A            | The function to run when the timer finishes

### repeat\_from(\_time, \_interval, \_callback)
Start a new timer to execute the callback at the specified time and then repeat at the specified interval after that.

Parameter         | Type           | Required       | Default        | Description
----------------- | -------------- | -------------- | -------------- | ----------------
\_time            | integer/string | Yes            | N/A            | The time when the timer should end
\_interval        | float          | Yes            | N/A            | The interval between executions of the timer in seconds
\_callback        | function       | Yes            | N/A            | The function to run when the timer finishes

### cancel()
Cancel an existing running timer if there is one.

### pause()
Pause the execution of any timer.

### unpause()
Unpause the execution of any timer.

### wakeup(\_duration, \_callback)
Start a new timer to execute the callback after the specified duration.
Multiple timers can be created using `wakeup()` and all use a shared timer.
This method returns the ID of the timer created.

_Note: the shared timer may reduce timer accuracy_

Parameter         | Type           | Required       | Default        | Description
----------------- | -------------- | -------------- | -------------- | ----------------
\_duration        | float          | Yes            | N/A            | The duration of the timer in seconds
\_callback        | function       | Yes            | N/A            | The function to run when the timer finishes

### cancelwakeup(id)
Cancels the timer with the specified ID.

Parameter         | Type           | Required       | Default        | Description
----------------- | -------------- | -------------- | -------------- | ----------------
id                | string         | Yes            | N/A            | The ID of the timer to cancel

# License

The Timer library is licensed under the [MIT License](LICENSE).
