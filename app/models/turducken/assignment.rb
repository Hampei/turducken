module Turducken
  class Assignment
    include Mongoid::Document
    include Mongoid::Timestamps::Created

    field :status
    field :assignment_id
    field :answers, :default => ""

    belongs_to :job, :class_name => 'Turducken::Job'
    belongs_to :worker

    validates_uniqueness_of :assignment_id

    def approve!(feedback = nil)
      RTurk::ApproveAssignment(:assignment_id => assignment_id, :feedback => feedback)
      status = :approved
      save
    end
  
    def abandoned?
      status == 'Abandoned'
    end
  
    def submitted?
      status == 'Submitted'
    end

    def approved?
      status == 'Approved'
    end

    def rejected?
      status == 'Rejected'
    end
    
    def self.create_or_update_from_mturk(job, rturk_assignment)
      #make sure we have a worker
      worker = Worker.find_or_create_by(:turk_id => rturk_assignment.source.worker_id)
      
      # get the results
      answers = rturk_assignment.source.answers

      # update our local assignment
      assignment = find_or_create_by(:assignment_id => rturk_assignment.id)
      assignment.worker = worker
      assignment.answers = answers
      assignment.save
      job.turducken_assignment_event(assignment, :finished)
      assignment
    end

  end
end
