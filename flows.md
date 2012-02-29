Flows of hits and assignments through the system
================================================

* rjob == resque job, to differentiate from turducken job.
* app == the application build on top of Turducken.

There are a lot of events happening, most of which which can fail and disrupt the system. When this happens it  would be nice if it can be retried, either automatically or manually. Using Resque makes some of these things easier, since a failed rjob will go into the failed queue and can be restarted. Any events to be called after a state has changed (so not after_enter instead of enter in stateflow) is put in a separate rjob, since they depend on app-logic, so failing and repeating them should be separate from internal actions. This does mean a lot more jobs though.

Assumptions
-----------

* _One worker, One queue_: To make things easier for now, Turducken only supports one Resque worker, meaning that a lot of processes will be done sequentially without fear of race conditions. 
* _Saving new state to db error will be rare_. All jobs start with a query, so if that doesn't fail, we assume the simple write will be fine and the problem will be rare or big enough for an engineer to have a look at it. The JOb will be flagged as failed, but can't be requeued without risking duplicate events or other errors. This is important, since handling all these errors correctly makes things many times more complicated. It is up to the requeue engineer to recognise the error and figure out a way forward.
* _Enqeueuing Resque jobs will fail rarely_. Turducken doesn't handle this correctly. Some rjobs are enqueued after_enter on states, meaning the new state has already been saved. This is needed to prevent race-conditions as the rjob being queued will expect the state to have changed already. 
* The app will make sure emails are send out to engineers when enqueue fails.
** When enqueue fails, the rjob will not be set to failed, since resque is screwy.
* kill -9 worker will fuck up state, that is life with resque.
* resque losing jobs will fuck up state.

Flows
=====

If an enqueue fail is not mentioned explicitly, an engineer will have to fix it. 

assignments
-----------

### Creation (GetAssignmentResults or GetMissedAssignment)

1. Assignment comes in from amazon with state :submitted (might have come in before)
2. Create local Assignment{type:submitted} or find existing one.
  * Create Error: rjob fails, can be requeued or will be handled by get_missed_assignments job.
3. Check if assignment.submitted?, otherwise we're done here to prevent duplicate events.
4. Enqueue assignment_submitted job
  * Queueu Error: will be handled by get_missed_assignment job or by engineer.

### AssignmentSubmitted

1. Check if state is correct.
2. run on_assignment_submitted callbacks on job.
  * AssignmentException: enqueue reject job and exit.
  * other Exceptions: set state to Errored and exit.
3. if auto_approve: Enqueue assignment_approved job  
   else: Enqueue assignment_pending_approval job.
  * Error: engineer create queue by hand.
  
### AssignmentRejected

1. Check if state is correct (done by stateflow)
  * Error: rjob fails, engineer check state requeue or delete job.
2. Send rejected command to amazon
  * Error Amazon InvalidAssignmentState: ignore (TODO make local state, amazon state)
  * Error: rjob fails, requeue
3. save state
  * Error: rjob fail, can be requeued
4. enqueue rejected_event job
  * Error: engineer create queue by hand.
5. enqueue check_job_progress job
  * Error: Will be handled by cronjob over all unfinished jobs (TODO!)

### AssignmentApproved

Same as Rejected, /reject/approve/gi

= HandleEvent( approved, rejected )

1. run event callbacks
  * Error: rjob fails, can be requeued (depending on app)
  
### CheckJobProgress (not yet implemented like this)

1. check state
  * if finished, ignore request
  * if not running yet: rjob fails: Engineer should check how this could happen or can ignore.
2. check if more assignment are needed to (after rejected)
  * call extend_hit
3. else check if job has all assignments and all are either approved or rejected
  * call finish

#### extend_hit

1. extend hit with more assignments
  * RTurkError: rjob fails, requeue
2. increase hit_num_assignments
  * MongoidError: rjob fails, engineer has fix.  
    If this step failed before, mongo and turk would be out of sync.  
    TODO: Better options would be to call RTurk::GetHIT and get the number from there, then we could requeue.
3. transition state to running again (will probably still be running)
  * Error: rjob fails, engineer has to fix.

#### finish

1. transition to finished state
  * MongoidError: rjob fails, requeue
2. enqueue disposal of hit on amazon
3. enqueue on_job_finished

### dispose HIT job

1. call RTurk::DisposeHit
  * RTurkError: rjob fails, requeue, if persists, have engineer check.

### on_job_finished job

1. call job#on_job_finished
  * Error: depending on app, might requeue or have engineer check.
