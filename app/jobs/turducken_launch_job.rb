class TurduckenLaunchJob
  @queue = :mturk

  def self.perform(job_id)
    job = Turducken::Job.find(job_id)
    return unless job.launching? or job.new?
    #TODO: verify we found the job

    h = RTurk::Hit.create(:title => job.hit_title) do |hit|
      hit.assignments = job.hit_num_assignments
      hit.description     = job.hit_description
      hit.reward          = job.hit_reward
      hit.lifetime        = job.hit_lifetime_s
      hit.duration        = job.hit_assignment_duration_s
      hit.keywords        = job.hit_keywords
      hq = job.hit_question
      if hq.first == '<'
        hit.question_form(job.hit_question)
      else
        hit.question(*hq)
      end
      add_qualifications(job, hit)
    end

    job.hit_id = h.id
    job.hit_url = h.url
    job.hit_type_id = h.type_id

    set_notifications(job)

    # if we made it this far, consider the job launched!
    job.launched!
    job.save
  end
  
  def self.set_notifications(job)
    # create the notification for this specific HIT Type
    notification = RTurk::Notification.new
    notification.destination = "#{Turducken.callback_host}/turducken/notifications"
    notification.transport   = 'REST'
    notification.version     = '2006-05-05'
    notification.event_type  = [ "AssignmentAccepted", "AssignmentAbandoned", "AssignmentReturned", "AssignmentSubmitted", "HITReviewable", "HITExpired" ]

    RTurk::SetHITTypeNotification(:hit_type_id => job.hit_type_id,
                                  :notification => notification,
                                  :active => true)
  end
  
  # add qualification to the hit, evaluating Proc values in the hash.
  def self.add_qualifications(job, hit)
    job.qualifications.each do |s,h|
      h.each do |k,v|
        h[k] = job.instance_eval(&v) if v.is_a? Proc
      end
      hit.qualifications.add(s, h)
    end
  end
end
      