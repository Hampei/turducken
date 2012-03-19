class TurduckenRejectAssignmentJob
  @queue = :mturk

  # <b>DEPRECATED:</b> Please use <tt>TurduckenAssignmentJob :reject</tt> instead.
  def self.perform(assignment_id)
    assignment = Turducken::Assignment.find(assignment_id) or raise 'unknown id'
    assignment.reject!
  end
end
