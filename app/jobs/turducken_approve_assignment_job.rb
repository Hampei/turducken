class TurduckenApproveAssignmentJob
  @queue = :mturk

  def self.perform(assignment_id)
    assignment = Turducken::Assignment.find(assignment_id) or raise 'unknown id'
    assignment.approve!
  end
end
