class Job < Turducken::Job
  field :nro_assignments_finished, :default => 0

  has_many :workers
  auto_approve
  set_defaults :hit_reward => 0.10, :hit_num_assignments => 5, :hit_lifetime_s => 3600
  
  def title
    'job title'
  end
  
  def description
    'description of the job'
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