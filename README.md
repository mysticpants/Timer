# Timer

A simple timer class with one-off and interval timers all of which can be cancelled.

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
\_params          | string         | No             | null           | TODO
\_send\_self      | boolean        | No             | false          | TODO

#### Example

```squirrel
// initialise the class
TODO
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
\_params          | string         | Yes            | N/A            | TODO

### set(\_duration, \_callback)
Start a new timer to execute the callback after the specified duration.

Parameter         | Type           | Required       | Default        | Description
----------------- | -------------- | -------------- | -------------- | ----------------
\_duration        | float          | Yes            | N/A            | The duration of the timer in seconds
\_callback        | function       | Yes            | N/A            | The function to run when the timer finishes

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

### onIdle()
### wakeup()
### cancelwakeup()


# License

The Timer library is licensed under the [MIT License](LICENSE).
