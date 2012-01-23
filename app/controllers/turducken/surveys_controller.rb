# DO NOT USE
# failed attempt to create one controller for all surveys. 
# would take the survey-model and any extra parameters needed for the view from the job-model
# but leads to too much controller code in the model or views. 
#
# Will instead look at making it easier to create such a controller in the application.
#
# Will leave this here for now for testing.
# Henk.

# Parameters: {
  # "assignmentId"=>"2BLHV8ER9Y8TL4LPNZD5RFHS4U9R4K", 
  # "hitId"=>"25RZ6KW4ZMAZF1UU9MH0VNNVRDD7GV", 
  # "workerId"=>"A3LP6T9VE9EKJQ", 
  # "turkSubmitTo"=>"https://www.mturk.com"}
module Turducken
  class SurveysController < ActionController::Base
    
    def show
      job = Turducken::Job.where(:hit_id => params[:hitId]).first
      @disabled = Turducken::FormHelper::disable_form_fields?(params)
      
      if @disabled
        @model = job.survey_model_example if job.respond_to? :survey_model_example
      else
        @model = job.survey_model if job.respond_to? :survey_model
      end
       
      render "/turducken/#{job.class.to_s.underscore}" 
    end
  end
end
