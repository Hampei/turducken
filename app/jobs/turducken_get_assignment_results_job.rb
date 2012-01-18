class TurduckenGetAssignmentResultsJob
  @queue = :mturk

  def self.perform(hit_id, assignment_id)
    job = Job.where(:hit_id => hit_id).first
    hit = job.as_hit
    assignments = hit.assignments
    
    assignments.each do |ass|
      #find this assignment
      if ass.id == assignment_id
        assignment = Turducken::Assignment.create_or_update_from_mturk(job, ass)
        assignment.approve!
      end
    end
    
#    Pusher['veracitix-jobs'].trigger('created', @job.attributes)
  end

end

