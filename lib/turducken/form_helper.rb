require 'action_view'

module Turducken
  module FormHelper

    # params: 
    def turducken_form_for(record, params, options = {}, &proc)
      options[:url] = submit_url(params)
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
    
    private

    def submit_url(params)
      Turducken.fake_external_submit ? 'turducken/fake_external_submit' :
        "#{params[:turkSubmitTo]}/mturk/externalSubmit"
    end

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
