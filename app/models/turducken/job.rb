module Turducken
  class Job
    include Mongoid::Document
    include Mongoid::Timestamps
    include Stateflow
    Stateflow.persistence = :mongoid #TODO find better way of doing this. maybe gem load order?

    field :hit_title
    field :hit_description
    field :hit_question_type # this should be either 'external' or 'questionform'
    field :hit_id
    field :hit_type_id
    field :hit_url
    field :hit_reward, type: Float
    field :hit_num_assignments, type: Integer
    field :hit_lifetime_s, type: Integer
    field :hit_assignment_duration_s, type: Integer # time user can spend on an assignment
    field :hit_question, type: String

    field :complete, type: Boolean
    field :state

    

    has_many :assignments, :class_name => 'Turducken::Assignment'
  #  has_many :workers, :through => :assignments

    class_attribute :attributes_defaults
    self.attributes_defaults = {}
    def self.set_defaults(attrs = {})
      self.attributes_defaults = self.attributes_defaults.merge(attrs)
    end
    def initialize(attributes = {}, options = {})
      super(self.attributes_defaults.merge(attributes), options)
    end
    
    class_attribute :qualifications
    self.qualifications = []
    def self.qualification(symbol, hash)
      self.qualifications << [symbol, hash]
    end

    after_create do
      launch!
    end

    before_destroy do
      hit = self.as_hit

      unless hit.nil?
        hit.expire! if (hit.status == "Assignable" || hit.status == 'Unassignable')
        hit.assignments.each do |assignment|
          assignment.approve! if assignment.status == 'Submitted'
        end
        hit.dispose!
      end
    end

    def self.auto_approve(y=true)
      @auto_approve = y
    end
    def self.auto_approve?
      @auto_approve
    end

    stateflow do
      state_column :state
      initial :new

      state :new

      state :launching do
        enter :do_launch
      end

      state :running
    
      state :finished do
        enter :dispose_hit
      end

      event :launch do
        transitions :from => :new, :to => :launching, :if => :ready_to_launch?
        transitions :from => :new, :to => :new
      end
    
      event :launched do
        transitions :from => :new,       :to => :running
        transitions :from => :launching, :to => :running
      end
  
      event :finish do
       transitions :from => :running, :to => :finished
      end
    end

    #
    # Either get and return the HIT, or nil
    #
    def as_hit
      begin
        RTurk::Hit.find(hit_id)
      rescue RTurk::InvalidRequest => e
        nil
      end
    end

  class_attribute :turducken_assignment_callbacks
  self.turducken_assignment_callbacks = {}
  class << self
    [:finished, :accepted, :returned, :abandoned].each do |event|
      define_method "on_assignment_#{event}" do |&block|
        self.turducken_assignment_callbacks = self.turducken_assignment_callbacks.dup
        self.turducken_assignment_callbacks[event] ||= []
        self.turducken_assignment_callbacks[event] += [block]
      end
    end
  end

  def turducken_assignment_event(assignment, event_type)
    cb = self.class.turducken_assignment_callbacks
    return unless cb and cb[event_type]
    self.class.turducken_assignment_callbacks[event_type].each do |block|
      instance_exec(assignment, &block)
    end
  end


  private

    def ready_to_launch?
      # TODO: validation that the job is in a launchable state
      # need a url to question, amount of reward, auto-accept?, etc.
      true
    end
  
    def do_launch
      Resque.enqueue(TurduckenLaunchJob, self.id)
    end

    def dispose_hit
      # Resque.enqueue(DisoseHit, self.hit_id)
    end

  end
end
