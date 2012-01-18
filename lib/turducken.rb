require 'turducken/engine' if defined?(Rails)

module Turducken
  
  class << self
    attr_reader :callback_host

    def setup(opts ={})
      @callback_host = opts[:callback_host]
    end
  end
end

Dir.glob(File.join(File.dirname(__FILE__), 'turducken', 'operations', '*.rb')).each {|f| require f }
Dir.glob(File.join(File.dirname(__FILE__), 'turducken', '*.rb')).each {|f| require f }
