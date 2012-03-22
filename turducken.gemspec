$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "turducken/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "turducken"
  s.version     = Turducken::VERSION
  s.authors     = ["Henk van der Veen"]
  s.email       = ["henk.van.der.veen@gmail.com"]
  s.homepage    = "https://github.com/veracitix/turducken"
  s.summary     = "Making mTurk a little bit easier."
  s.description = "Rails engine that adds a mTurk Notification endpoint controller, and some tools for working with Jobs and Workers"

  s.files = Dir["{app,config,lib}/**/*"] + ["Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2"

  s.add_dependency 'bson_ext', "~> 1.5"
  s.add_dependency 'mongoid' , "~> 2.4"
  
  s.add_dependency 'rturk', "~> 2.6.0"
  # s.add_dependency 'stateflow', :git => 'https://github.com/hampei/stateflow.git', :branch => '1.4.2'
  
end
