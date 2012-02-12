module Turducken
  class MtController < ActionController::Base
    layout nil

    #
    # these are run without requiring logins,
    # auth is done via signature on the params
    #
    def notifications
      event_types = params.select{ |k,v| k.end_with? "EventType" }
      num_of_events = event_types.size
      
      Rails.logger.debug "Received #{num_of_events} events from mTurk"
      
      signature = params[:Signature]
      timestamp = params[:Timestamp]
      
      #hash_string = "AWSMechanicalTurkRequesterNotificationNotify#{params[:Timestamp]}"
      
      #taking the signature of the hash_string (using our AWS key) should equal
      # the Signature that AWS sent us
      
      for i in 1..num_of_events do
        event = MturkEvent.new
        event.type          = params["Event.#{i}.EventType"]
        
        #
        # We may get the occasional Ping from Amazon, track it
        # but don't try to pull out info that is not there.
        #
        unless event.type == 'Ping'
          event.hit_type_id   = params["Event.#{i}.HITTypeId"]
          event.hit_id        = params["Event.#{i}.HITId"]
          event.assignment_id = params["Event.#{i}.AssignmentId"]
          event.time          = params["Event.#{i}.EventTime"]
        end

        event.save
        
        #
        # What type of events do we get from mTurk and what data can we pull from each one.
        # 
        case event.type
        
        when "AssignmentAccepted"
          # perhaps just create an event for this job, but don't keep track of the assignment yet.
          
          # - create an empty Assignment using the AssignmentId
          # job = Job.where(:hit_id => event.hit_id).first
          # assignment = job.assignments.create(:assignment_id => event.assignment_id, :status => :accepted)
          
        when "AssignmentAbandoned"
          # perhaps just create an event for this job, but don't keep track of the assignment yet.
          
          # - This happens when a worker does not complete an assignment within the AssignmentDurationInSeconds
          # - Update Assignment state to Abandoned
          # - We can now see that a worker has abandoned one of our jobs, and use that for internal stats
          # assignment = Assignment.find_or_create_by(:assignment_id => event.assignment_id)
          # assignment.status = :abandoned
          # assignment.save

        when "AssignmentReturned"
          # perhaps just create an event for this job, but don't keep track of the assignment yet.

          # - A Worker has purposely returned an Assignment
          # - Update the assignment state to Returned
          # - We can now see that a worker has returned one of our jobs, and use that for internal stats
          # assignment = Assignment.find_or_create_by(:assignment_id => event.assignment_id)
          # assignment.status = :returned
          # assignment.save

        when "AssignmentSubmitted"
          # - Use the AssignmentID to call GetAssignmentsForHIT
          # - pull in the results and append them to the Assignment
          # - Auto-Approve the Assignment (bonus for expediency?)
          Resque.enqueue(TurduckenGetAssignmentResultsJob, event.hit_id, event.assignment_id)

        when "HITReviewable"
          # - call GetAssignmentsForHIT to make sure we have all the HIT results
          # - Auto-Approve any assignments if we have missed any
          # - Dispose of the HIT?
          # - Fire off the job.finish! event, which should update the client app UI
          Resque.enqueue(ReviewHitJob, event.hit_id)
        
        when "HITExpired"
          # - Either call DisableHIT (which takes it off the marketplace) or call
          #    the HIT or increase the payout and extend it
          # - Should create a notification to Admin panel or possibly the user?
        
        when "Ping"
          # - Used for Amazon Internal stuff. We should at least track these events to see how common they are
          #   or if they correlate with other system activity.
        
        else
          #
          # wtf, mate?
          #
        end
      
      end
      render :text => 'ok'
    
    end

    def send_test_notification
      # create the notification for this specific HIT Type
      notification = RTurk::Notification.new
      notification.destination = "#{Turducken.callback_host}/mt/notifications"
      notification.transport   = 'REST'
      notification.version     = '2006-05-05'
      notification.event_type  = [ "AssignmentAccepted", "AssignmentAbandoned", "AssignmentReturned", "AssignmentSubmitted", "HITReviewable", "HITExpired" ]
    
      RTurk.SendTestEventNotification(:notification => notification, :test_event_type => 'AssignmentAccepted')
    end

  end
end
