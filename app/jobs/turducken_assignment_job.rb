# calls job.check_progress!
# should be called on approve and on reject of assignment.
class TurduckenAssignmentJob
  @queue = :mturk

  def self.perform(action, assignment_id, *args)
    assignment = Turducken::Assignment.find(assignment_id) or raise 'unknown id'
    case action.to_sym
    when :approve
      assignment.approve! unless assignment.approved?
    when :reject
      assignment.feedback = args[0]
      assignment.reject! unless assignment.rejected?
    when :grant_bonus
      amount, feedback = args
      assignment.grant_bonus(amount.to_f, feedback)
    end
  end
end