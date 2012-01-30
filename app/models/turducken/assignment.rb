module Turducken
  class Assignment
    include Mongoid::Document
    include Mongoid::Timestamps::Created

    field :status, :type => String
    field :assignment_id, :type => String
    field :answers, :type => Hash, :default => {}
    field :extra, :type => Hash, :default => {}

    belongs_to :job, :class_name => 'Turducken::Job'
    belongs_to :worker

    validates_uniqueness_of :assignment_id

    # TODO: start using stateflow here.
    def approve!(feedback = nil)
      RTurk::ApproveAssignment(:assignment_id => assignment_id, :feedback => feedback)
      self.status = 'Approved'
      save
    end
    
    def reject!(feedback)
      RTurk::RejectAssignment(:assignment_id => assignment_id, :feedback => feedback)
      self.status = 'Rejected'
      save
    end
    
    def errored!(exception)
      self.status = 'Errored'
      self.extra[:error] = exception.inspect
      save
    end
    
    def pending_approval!
      self.status = 'PendingApproval'
      self.save
    end
  
    # assignment has not been finished (in time) by the turker.
    def abandoned?
      status == 'Abandoned'
    end
  
    # assignment has been done, but has not been processed yet.
    def submitted?
      status == 'Submitted'
    end

    # answer has been succesfully processed by the job, but needs to be approved by some person or process.
    # This state leaves the rturk_assignment_state on submitted.
    def pending_approval?
      status == 'PendingApproval'
    end

    # answer has been approved, turker has been paid.
    def approved?
      status == 'Approved'
    end

    # answer has been rejected, either by specific code or by a user.
    def rejected?
      status == 'Rejected'
    end
    
    # an error was thrown while processing the assignment, probably code error, needs a programmer.
    # This state leaves the rturk_assignment_state on submitted.
    def errored?
      status == 'Errored'
    end

    # create or update an assignment with information from mechanical turk.
    # for now only handles submitted rturk_assignments. 
    # skips assignments that have already been processed.
    # calls the relevant callbacks on the job-model
    # approves or rejects the assignment if possible.
    def self.create_or_update_from_mturk(job, rturk_assignment)
      return unless rturk_assignment.submitted? # TODO, check implementation of state changes.

      # update our local assignment
      assignment = find_or_create_by(:assignment_id => rturk_assignment.id)
      return if assignment.pending_approval? or assignment.errored?

      #make sure we have a worker
      worker = Turducken.worker_model.find_or_create_by(:turk_id => rturk_assignment.source.worker_id)
      
      assignment.worker = worker
      assignment.answers = get_normalised_answers(rturk_assignment)
      assignment.status = rturk_assignment.status
      assignment.save

      handle_assignment_event(job, assignment)
    end

    def self.handle_assignment_event(job, assignment)
      if assignment.submitted?
        begin
          job.turducken_assignment_event(assignment, :finished)
          if job.class.auto_approve?
            assignment.approve!
            assignment.reload
          else
            assignment.pending_approval!
          end
        rescue Turducken::AssignmentException => e
          logger.info("assignment #{assignment.assignment_id} rejected")
          assignment.reject! e.feedback
        rescue Exception => e
          assignment.errored! e
        end
      end
          
      assignment
    end

  private

    def self.get_normalised_answers(rturk_assignment)
      answers = rturk_assignment.source.answers
      Rack::Utils.parse_nested_query(answers.to_query)
    end

  end
end
