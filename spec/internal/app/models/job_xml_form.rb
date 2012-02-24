class JobXMLForm < Turducken::Job

  set_defaults :require_approved_assignments => true
  field :nro_assignments_finished, :default => 0

  on_assignment_submitted do |assignment|
    self.nro_assignments_finished += 1
    save
  end

  def hit_question
    "<Overview></Overview><Question></Question>"
  end
end