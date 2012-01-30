require 'turducken/engine' if defined?(Rails)

module Turducken
  
  class << self
    attr_reader :callback_host, :worker_model, :fake_external_submit

    def setup(opts ={})
      @callback_host = opts[:callback_host]
      @worker_model = opts[:worker_model] || ::Worker
      @fake_external_submit = opts[:fake_external_submit]
    end
  end
  
  class AssignmentException < Exception
    attr :feedback
    def initialize(feedback)
      @feedback = feedback
    end
  end
end

require 'turducken/form_helper'
require 'turducken/controller'
Dir.glob(File.join(File.dirname(__FILE__), 'turducken', 'operations', '*.rb')).each {|f| require f }
Dir.glob(File.join(File.dirname(__FILE__), 'turducken', '*.rb')).each {|f| require f }
