class Job < Turducken::Job
  field :nro_assignments_finished, :default => 0

  on_assignment_finished do |assignment|
    self.nro_assignments_finished += 1
    save
  end

  def hit_question
    "<Overview></Overview><Question></Question>"
  end
end