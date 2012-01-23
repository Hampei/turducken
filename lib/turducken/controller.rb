module Turducken
  module Controller
    def self.included(model)
      model.class_eval do
        helper_method :is_preview?
        def is_preview?
          Turducken::FormHelper::disable_form_fields?(params)
        end
  
        #after_filter :save_survey_view, :only => ...
        def save_survey_views
          unless is_preview?
            s = SurveyView.new
            s.hit_id = params[:hitId]
            s.assignment_id = params[:assignmentId]
            s.ip_address = request.remote_ip
            s.browser = request.env['HTTP_USER_AGENT']
            s.save!
          end
        end
      end
    end
  end
end
