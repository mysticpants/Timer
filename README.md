# Scheduler

A simple class to manage jobs with one-off and interval timers all of which can be cancelled.
Can be used to create multiple jobs that actually share a single timer which may be helpful on
the agent where the number of active timers is limited. This class also allows the user to pass
parameters to the callbacks they provide for each job.

To add this library to your model, add the following lines to
the top of your agent code:

```
#require "Scheduler.class.nut:1.0.0"
```

## Class Usage

### Scheduler

This class managers all the jobs and is used mostly for creating new jobs. Each method for creating a job will return the new Job class instance.

#### Scheduler.set(\_duration, \_callback, [...])
Start a new timer to execute the callback after the specified duration. Returns the new job.

Parameter         | Type           | Required       | Default        | Description
----------------- | -------------- | -------------- | -------------- | ----------------
\_duration        | float          | Yes            | N/A            | The duration of the timer in seconds
\_callback        | function       | Yes            | N/A            | The function to run when the timer finishes
...               | any            | No             | N/A            | Optional parameters that will be passed to the callback

##### Example

```squirrel
function myFunc(msg) {
    server.log(msg);
}
sch <- Scheduler();
job1 <- sch.set(5, myFunc, "Timer fired");
```

#### Scheduler.at(\_time, \_callback, [...])
Create a new job with a callback to execute at a specified time. The time can either be provided as an integer
representing the number of seconds that have elapsed since midnight on 1 January 1970 OR as a string in the following
format: "January 01, 2017 12:30 PM". Returns the new job.

Parameter         | Type           | Required       | Default        | Description
----------------- | -------------- | -------------- | -------------- | ----------------
\_time            | integer/string | Yes            | N/A            | The time when the timer should end
\_callback        | function       | Yes            | N/A            | The function to run when the timer finishes
...               | any            | No             | N/A            | Optional parameters that will be passed to the callback

#### Scheduler.repeat(\_interval, \_callback, [...])
Create a new job with a callback that will repeat at the specified interval. Returns the new job.

Parameter         | Type           | Required       | Default        | Description
----------------- | -------------- | -------------- | -------------- | ----------------
\_interval        | float          | Yes            | N/A            | The interval between executions of the timer in seconds
\_callback        | function       | Yes            | N/A            | The function to run when the timer finishes
...               | any            | No             | N/A            | Optional parameters that will be passed to the callback

#### Scheduler.repeat\_from(\_time, \_interval, \_callback, [...])
Create a new job with a callback to execute at the specified time and then repeat at the specified interval after that. Returns the new job.

Parameter         | Type           | Required       | Default        | Description
----------------- | -------------- | -------------- | -------------- | ----------------
\_time            | integer/string | Yes            | N/A            | The time when the timer should end
\_interval        | float          | Yes            | N/A            | The interval between executions of the timer in seconds
\_callback        | function       | Yes            | N/A            | The function to run when the timer finishes
...               | any            | No             | N/A            | Optional parameters that will be passed to the callback

#### Scheduler.tzoffset(offset)
Set the offset for the timezone.

Parameter         | Type           | Required       | Default        | Description
----------------- | -------------- | -------------- | -------------- | ----------------
offset            | integer        | No             | null           | The time offset in hours

### Job

An instance of this class is created for each new job (timer) created. Any action performed on an existing job will be done using a method on this class.

#### Job.now()
Immediately execute this job. Returns this.

#### Job.pause()
Pause the execution of the job's timer. Returns this.

#### Job.unpause()
Unpause the execution of the job's timer. Returns this.

#### Job.cancel()
Cancel this job. Returns this.

#### Job.reset([rstDur])
Reset this job (i.e. restart the timer). Optionally, a different duration to the
original can be passed to this method. This can't be used for jobs created with
the `Scheduler.at()` method or during the first timer of jobs created with the
`Scheduler.repeatFrom()` method (can be used for `Scheduler.repeatFrom()` jobs after
they've fired the first time). Returns this.

Parameter         | Type           | Required       | Default           | Description
----------------- | -------------- | -------------- | ----------------- | ----------------
rstDur            | float          | No             | original duration | The optional new timer duration

# License

The Scheduler library is licensed under the [MIT License](LICENSE).
