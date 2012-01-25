Turducken
=======

A plugin build on top of RTurk to make interaction with amazon turk easier.

How to use
----------

### initializer

puts something like this in config/initializers/turducken.rb

    if Settings[:webhook_host].nil?
      host = 'http://turducken.herokuapp.com'
    else
      host = Settings[:webhook_host]
    end
    OurTurk.setup(:callback_host => host)


### Turducken::Job

For any job you want to run on amazon turk create a subclass of Turducken::Job.

You will often want to implement the following methods instead of saving the whole thing to the database.

 `title`: returns title of the job in mturk  
 `hit_question`: Should return either the XML of the question in mturk QuestionForm format
 [api](http://docs.amazonwebservices.com/AWSMechTurk/latest/AWSMturkAPI/ApiReference_QuestionFormDataStructureArticle.html) or the url of the ExternalForm and a hash of options (`return survey_url, :frame_height => 500, :id => id`)
 `description`: Extra info for mturker on how to complete the mturk task  
 `hit_reward`: money to be paid for task in dollars default 0.10

Other fields:  
 `hit_num_assignments`, type: Integer, :default => 5  
 `hit_lifetime`, type: Integer  
 `hit_id`: after save, given by mturk  
 `hit_type_id`: could be specified later, but for now is given by mturk (new one for every hit)  
 `state`: [:new, :launching, :running, :finished], state_machine handled by plugin.

fields not used at the moment:  
 `hit_question_type` # this should be either 'external' or 'questionform'  
 `hit_url`

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
 `answers`: QuestionFormAnswers XML. [api](http://docs.amazonwebservices.com/AWSMechTurk/latest/AWSMturkAPI/ApiReference_QuestionFormAnswersDataStructureArticle.html)


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
