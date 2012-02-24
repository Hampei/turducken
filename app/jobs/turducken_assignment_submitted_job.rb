class TurduckenAssignmentSubmittedJob
  @queue = :mturk

  def self.perform(assignment_id)
    assignment = Turducken::Assignment.find(assignment_id) or raise 'unknown id'
    assignment.handle_submitted
  end
end
