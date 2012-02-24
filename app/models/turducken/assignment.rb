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

    scope :rejected, where(state: 'rejected')
    scope :approved, where(state: 'approved')
    # TODO find a way to query for 2 options in mongoid
    # scope :approved_or_rejected, where("state = 'rejected' or state = 'approved'")
    
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
        enter :rturk_approve
        after_enter do |a|
          Resque.enqueue(TurduckenAssignmentEventJob, a.id, :approved)
          Resque.enqueue(TurduckenCheckJobProgressJob, a.job_id)
        end
      end

      # will never be finished. Turker either clicked abondon button or the assignment timed out.
      state :abandoned

      # answer has been rejected, either by specific code or by a user action.
      state :rejected do
        enter :rturk_reject
        after_enter do |a|
          Resque.enqueue(TurduckenAssignmentEventJob, a.id, :rejected)
          Resque.enqueue(TurduckenCheckJobProgressJob, a.job_id)
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
    
    def rturk_approve
      rturk_ignoring_state_error do
        RTurk::ApproveAssignment(:assignment_id => assignment_id, :feedback => feedback)
      end
    end
    
    def rturk_reject
      rturk_ignoring_state_error do
        RTurk::RejectAssignment(:assignment_id => assignment_id, :feedback => feedback)
      end
    end

    # create or update an assignment with information from mechanical turk.
    # for now only handles submitted rturk_assignments. 
    # skips assignments that have already been processed.
    # calls the relevant callbacks on the job-model
    # approves or rejects the assignment if possible.
    def self.create_from_mturk(job, rturk_assignment)
      return unless rturk_assignment.submitted? # TODO, check implementation of state changes.
      return if where(assignment_id: rturk_assignment.id).exists?

      #make sure we have a worker
      worker = Turducken.worker_model.find_or_create_by(:turk_id => rturk_assignment.source.worker_id)

      assignment = new(
        assignment_id: rturk_assignment.id,
        answers: get_normalised_answers(rturk_assignment),
        job: job,
        worker: worker
      )
      assignment.set_current_state(machine.states[rturk_assignment.status.underscore.to_sym])
      assignment.save

      Resque.enqueue(TurduckenAssignmentSubmittedJob, assignment.id)
    end

    def handle_event(type)
      job.turducken_assignment_event(self, type)
    end

    def handle_submitted
      return unless submitted?
      begin
        job.turducken_assignment_event(self, :submitted)
        if job.class.auto_approve?
          approve!
          reload
        else
          pending_approval!
        end
      rescue Turducken::AssignmentException => e
        logger.info("assignment #{assignment_id} rejected")
        self[:feedback] = e.feedback
        reject!
      rescue Exception => e
        extra['error'] = e.inspect
        extra['backtrace'] = e.backtrace
        error!
      end
    end

  private

    def self.get_normalised_answers(rturk_assignment)
      answers = rturk_assignment.source.answers
      Rack::Utils.parse_nested_query(answers.to_query)
    end

    # to survive approving an approved/rejected assignment 
    # (when amazon and mongodb are out of sync due to save error)
    def rturk_ignoring_state_error(&block)
      begin
        yield
      rescue RTurk::InvalidRequest
        raise unless $!.message.start_with? 'AWS.MechanicalTurk.InvalidAssignmentState'
        logger.error("amazon was in unexpected state for assignment #{self.inspect}, might want to check.")
      end
    end

  end
end
