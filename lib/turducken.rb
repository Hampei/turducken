require 'turducken/engine' if defined?(Rails)

module Turducken
  
  class << self
    attr_reader :callback_host, :worker_model

    def setup(opts ={})
      @callback_host = opts[:callback_host]
      @worker_model = opts[:worker_model] || ::Worker
    end
  end
end

require 'turducken/form_helper'
Dir.glob(File.join(File.dirname(__FILE__), 'turducken', 'operations', '*.rb')).each {|f| require f }
Dir.glob(File.join(File.dirname(__FILE__), 'turducken', '*.rb')).each {|f| require f }
