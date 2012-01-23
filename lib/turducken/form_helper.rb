require 'action_view'

module Turducken
  module FormHelper

    # Totally stolen from the Turkee Gem.
    # Rails 3.1.1 form_for implementation with the exception of the form action url
    # will always point to the Amazon externalSubmit interface and you must pass in the
    # assignment_id parameter.
    def turducken_form_for(record, params, options = {}, &proc)
      options[:url] = "#{params[:turkSubmitTo]}/mturk/externalSubmit"
      options[:disabled] = true if params[:assignmentId].nil? || Turducken::FormHelper::disable_form_fields?(params[:assignmentId])
      form_for(record, options) { |f|
         params.each do |k,v|
           unless k =~ /^action$/i || k =~ /^controller$/i || v.class != String
             concat(hidden_field_tag(k, v))
           end
         end
         proc.call(f)
      }
    end

    # Returns whether the form fields should be disabled or not (based on the assignment_id)
    def self.disable_form_fields?(assignment)
      assignment_id = assignment.is_a?(Hash) ? assignment[:assignmentId] : assignment
      (assignment_id.nil? || assignment_id == 'ASSIGNMENT_ID_NOT_AVAILABLE')
    end
  end
end
ActionView::Base.send :include, Turducken::FormHelper
