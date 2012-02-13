class TurduckenLaunchJob
  @queue = :mturk

  def self.perform(job_id)
    job = Turducken::Job.find(job_id)
    #TODO: verify we found the job

    h = RTurk::Hit.create(:title => job.title) do |hit|
      hit.max_assignments = job.hit_num_assignments
      hit.description     = job.description
      hit.reward          = job.hit_reward
      hit.lifetime         = job.hit_lifetime_s
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
    notification.destination = "#{Turducken.callback_host}/mt/notifications"
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
      