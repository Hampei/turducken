class TurduckenApproveAssignmentJob
  @queue = :mturk

  # <b>DEPRECATED:</b> Please use <tt>TurduckenAssignmentJob :approve</tt> instead.
  def self.perform(assignment_id)
    assignment = Turducken::Assignment.find(assignment_id) or raise 'unknown id'
    assignment.approve! unless assignment.approved?
  end
end
