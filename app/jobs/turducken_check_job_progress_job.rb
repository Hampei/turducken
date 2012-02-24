# calls job.check_progress!
# should be called on approve and on reject of assignment.
class TurduckenCheckJobProgressJob
  @queue = :mturk

  def self.perform(job_id)
    job = Turducken::Job.find(job_id) or raise 'unknown id'
    job.check_progress!
  end
end