Turducken
=======

A plugin build on top of RTurk to make interaction with amazon turk easier.

How to use
----------

* create initialiser
* create a Worker-model (include Turducken::Worker) to hold info on workers
* subclass from Turducken::Job to create your jobs
** every instantiation will correspond to a HIT on amazon
** processes assignments coming in for the hit
* include Turducken::Controller in controllers to create external\_forms (optional)


### initialiser

puts something like this in config/initializers/turducken.rb

    RTurk::logger.level = Logger::DEBUG if Rails.env.development?
    RTurk.setup(ENV["AWSACCESSKEYID"], ENV["AWSSECRETACCESSKEY"], :sandbox => !Rails.env.production?)
    
    if Settings[:webhook_host].nil?
      host = 'http://turducken.herokuapp.com'
    else
      host = Settings[:webhook_host]
    end
    Turducken.setup(:callback_host => host)


### Worker

    class Worker
      # include Mongoid::Document / field turk_id / has_many assignments.
      include Turducken::Worker
      include Mongoid::Timestamps
    
      field :sex, :type => String
    end


### Turducken::Job

    class Job < Turducken::Job
      field :nro_assignments_finished, :default => 0
      field :market, :type => String, :default => 'UK'
      
      has_many :workers
      # unless errors are thrown in on_assignment_finished, an assignment is approved automatically.
      auto_approve
    
      # instead of defining function, you can set default values like this. 
      set_defaults :hit_reward => 0.10, :hit_num_assignments => 5, :hit_lifetime_s => 3600
      
      # qualifications can be added using constants or Procs. 
      # Syntax same as RTurk::Hit.new.qualifications.add
      qualification :country, {:eql => Proc.new{market}}
      qualification :approval_rate, { :gt => 60 }
    
      def title
        "title for the job on amazon"
      end
      
      def description
        "Some info about what the job entails"
      end
      
      # Should return either the XML of the question in mturk QuestionForm format    [api](http://docs.amazonwebservices.com/AWSMechTurk/latest/AWSMturkAPI/ApiReference_QuestionFormDataStructureArticle.html) or the url of the ExternalForm and a hash of options
      def hit_question
        return Rails.application.routes.url_helpers.job_url(self), :frame_height => 300, :id => id
        # "<Overview>...</Overview><Question>...</Question>"
      end
    
      # handle incoming assignments. Will often create some object or save some result.
      # when AssignmentException is raised, the assignment is automatically rejected.
      # when other Exception is raised, the assignment is set to errored, so a programmer can have a look.
      on_assignment_finished do |assignment|
        sex = assignment.aswers['sex']
        unless %w(Male Female).includes? sex
          raise Turducken::AssignmentException, 'Illegal sex value'
        end
        worker = Worker.where(:turk_id => assignment.worker_id).first
        worker.sex = sex
        worker.save

        self.nro_assignments_finished += 1
        save
      end
    end

Other fields:  
 `hit_num_assignments`, type: Integer: number of people that should complete this hit.
 `hit_lifetime_s`, type: Integer: how long a turker has to finish the assignment after accepting it.

Fields set by system:

 `hit_id`: after save, given by mturk
 `hit_type_id`: could be specified later, but for now is given by mturk (new one for every hit)
 `state`: [:new, :launching, :running, :finished], state_machine handled by plugin.


#### assignments

Each Job has many assignments, these Assignments usually don't have to be subclassed, instead you handle the events in your Job-class by defining callbacks and using the data in your own datastructures.

    on_assignment_finished {|assignment| ... }
    on_assignment_accepted ... TODO - implement in mt_controller
    on_assignment_returned ...   " 
    on_assignment_abandoned ...  " 

    # check results, to see if turker has done his job correctly. 
    # defaults to true.
    def approve?(assignment)
      return assignment.answers['foo'] > 50
    end

Turducken::Assignment contains:

 `status`: ['Abandoned', 'Submitted', 'Approved', 'Rejected']
 `assignment_id`: given by mturk
 `answers`: normalized hash of the anwers eg: {'worker' => {'sex' => 'Female'}}

### Survey Controllers

    class JobsController < ActionController::Base
      include Turducken::Controller
      after_filter :save_survey_view, :only => :show
      def show
        if is_preview?
          # set some preview data for the job type
        else
          # load the real data
         end
      end
    end

requirements
------------
gems:
    gem 'rturk'           , :git => "https://github.com/mdp/rturk.git", :branch => "3.0pre"
    gem 'stateflow', :git => 'https://github.com/hampei/stateflow.git', :branch => '1.4.2'

- A resque server, configured in the main app.


TODO
----

- handle missed assignment events from amazon (when restarting app for example)
  - Could check for all assignments in cronjob. or smarter by remembering latest assignment of last check.
