# calls job.check_progress!
# should be called on approve and on reject of assignment.
class TurduckenJobJob
  @queue = :mturk

  def self.perform(action, job_id)
    job = Turducken::Job.find(job_id) or raise 'unknown id'
    case action.to_sym
    when :check_progress
      job.check_progress!
    when :on_job_finished
      job.on_job_finished
    end
  end
end