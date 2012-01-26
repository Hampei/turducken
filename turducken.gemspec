$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "turducken/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "turducken"
  s.version     = Turducken::VERSION
  s.authors     = ["Henk van der Veen "]
  s.email       = ["henk.van.der.veen@gmail.com"]
  s.homepage    = "TODO"
  s.summary     = "Exploring better ways to talk to mTurk"
  s.description = "Exploring better ways to talk to mTurk"

  s.files = Dir["{app,config,lib}/**/*"] + ["Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2"

  s.add_dependency 'bson_ext', "~> 1.5"
  s.add_dependency 'mongoid' , "~> 2.4"
  
  # s.add_dependency 'rturk', :git => "https://github.com/mdp/rturk.git", :branch => "3.0pre"
  # s.add_dependency 'stateflow', :git => 'https://github.com/hampei/stateflow.git', :branch => '1.4.2'
  
end
