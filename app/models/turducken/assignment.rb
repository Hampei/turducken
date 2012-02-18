module Turducken
  class Assignment
    include Mongoid::Document
    include Mongoid::Timestamps::Created
    include Stateflow
    Stateflow.persistence = :mongoid #TODO find better way of doing this. maybe gem load order?

    field :state, :type => String
    field :assignment_id, :type => String
    field :answers, :type => Hash, :default => {}
    field :extra, :type => Hash, :default => {}
    field :feedback, :type => String

    belongs_to :job, :class_name => 'Turducken::Job'
    belongs_to :worker
    belongs_to :assignment_result, :polymorphic => true

    validates_uniqueness_of :assignment_id

    stateflow do
      state_column :state
      initial :submitted

      # assignment has been submitted, it should not stay here long, after successfully running the event it should
      # either move to approved or pending_approval.
      state :submitted

      # answer has been succesfully processed by the job, but needs to be approved by some person or process.
      # This state leaves the rturk_assignment_state on submitted.
      state :pending_approval

      # answer has been approved, turker has been paid.
      state :approved do
        enter do |a|
          RTurk::ApproveAssignment(:assignment_id => a.assignment_id, :feedback => a.feedback)
        end
      end

      # will never be finished. Turker either clicked abondon button or the assignment timed out.
      state :abandoned

      # answer has been rejected, either by specific code or by a user action.
      state :rejected do
        enter do |a|
          RTurk::RejectAssignment(:assignment_id => a.assignment_id, :feedback => a.feedback)
        end
      end

      # an error was thrown while processing the assignment, probably code error, needs a programmer.
      # This state leaves the rturk_assignment_state on submitted.
      state :errored

      event :approve do
        transitions :from => [:submitted, :pending_approval], :to => :approved
      end

      event :reject do
        transitions :from => [:submitted, :pending_approval], :to => :rejected
      end

      event :pending_approval do
        transitions :from => :submitted, :to => :pending_approval
      end

      event :error do
        transitions :from => :submitted, :to => :errored
      end
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
      assignment.set_current_state(machine.states[rturk_assignment.status.underscore.to_sym])
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
          assignment.feedback = e.feedback
          assignment.reject!
        rescue Exception => e
          assignment.extra[:error] = e.inspect
          assignment.extra[:backtrace] = e.backtrace
          assignment.error!
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
