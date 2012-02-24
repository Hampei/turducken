# fetches all assignment from all(last 100) running jobs, then checks if they exist in the database, 
# if not. creates a new assignment. exactly like the get_assignment_results job.
# 

class TurduckenGetMissedAssignmentJob
  @queue = :mturk

  def self.perform(hit_id = nil)
    jobs = hit_id ? Turducken::Job.running.where(:hit_id => hit_id) : Turducken::Job.running
    
    jobs.each do |job|
      hit = RTurk::Hit.new(job.hit_id)
      # TODO: handle more than the 100 assignment of first page
      assignments = hit.assignments
    
      assignments.each do |ass|
        if Turducken::Assignment.where(:assignment_id => ass.id).count == 0
          Turducken::Assignment.create_from_mturk(job, ass)
        end
      end
    end
  end
end
