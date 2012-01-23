require 'action_view'

module Turducken
  module FormHelper

    # params: 
    def turducken_form_for(record, params, options = {}, &proc)
      options[:url] = "#{params[:turkSubmitTo]}/mturk/externalSubmit"
      options[:builder] = TurdurckerFormBuilder
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
      (assignment_id.nil? || assignment_id.empty? || assignment_id == 'ASSIGNMENT_ID_NOT_AVAILABLE')
    end
    
    private
    
    class TurdurckerFormBuilder < ActionView::Helpers::FormBuilder
      helpers = field_helpers + 
        %w(time_zone_select date_select submit) -
        %w(hidden_field fields_for label)
      helpers.each do |helper|
        define_method helper do |*args|
          options = args.detect{ |a| a.is_a?(Hash) } || args.push({}).last
          options[:disabled] = @template.is_preview?
          super(*args)
        end
      end
    end
    
  end
end
ActionView::Base.send :include, Turducken::FormHelper
