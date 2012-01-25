class Job < Turducken::Job
  field :nro_assignments_finished, :default => 0

  has_many :workers
  auto_approve
  
  def survey_model_example
    Worker.new
  end
  
  def survey_model
    Worker.new
  end
  
  on_assignment_finished do |assignment|
    if assignment.answers['tweet'] =~ /illegal/
      raise Turducken::AssignmentException, 'the word illegal is illegal in tweets'
    end
    self.nro_assignments_finished += 1
    save
  end

  def hit_question
    return Rails.application.routes.url_helpers.job_url(self), :frame_height => 300
    # "<Overview></Overview><Question></Question>"
  end
end