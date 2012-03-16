class Job < Turducken::Job
  field :nro_assignments_finished, :type => Integer, :default => 0
  field :market, :type => String, :default => 'UK'

  has_many :workers
  auto_approve
  set_defaults :hit_reward => 0.10, :hit_num_assignments => 5, :hit_lifetime_s => 3600, 
    :hit_keywords => ['quick', 'easy']
  qualification :country, {:eql => Proc.new{market}}
  qualification :approval_rate, { :gt => 60 }
  qualification :adult, :eql => 1
  
  def hit_title
    'job title'
  end
  
  def hit_description
    'description of the job'
  end
  
  on_assignment_submitted do |assignment|
    if assignment.answers['tweet'] =~ /illegal/
      raise Turducken::AssignmentException, 'the word illegal is illegal in tweets'
    end
    if assignment.answers['tweet'] =~ /unexpected/
      raise 'random other error'
    end
    self.nro_assignments_finished += 1
    save
  end
  
  def do_approved(a); true; end
  on_assignment_approved do |assignment|
    do_approved(assignment)
  end
  
  def hit_question
    return Rails.application.routes.url_helpers.job_url(self), :frame_height => 300
    # "<Overview></Overview><Question></Question>"
  end
end