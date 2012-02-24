class TurduckenAssignmentEventJob
  @queue = :mturk

  def self.perform(assignment_id, event_type)
    assignment = Turducken::Assignment.find(assignment_id) or raise 'unknown id'
    assignment.handle_event(event_type.to_sym)
  end
end