class Job < Turducken::Job
  field :nro_assignments_finished, :default => 0

  has_many :workers
  
  def survey_model_example
    Worker.new
  end
  
  def survey_model
    Worker.new
  end

  on_assignment_finished do |assignment|
    self.nro_assignments_finished += 1
    save
  end

  def hit_question
    "<Overview></Overview><Question></Question>"
  end
end