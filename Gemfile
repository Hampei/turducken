source "http://rubygems.org"

gem 'rails'           , '3.1.1'
gem 'stateflow', :git => 'https://github.com/hampei/stateflow.git', :branch => '1.4.2'
gem 'resque'          , :git => 'https://github.com/defunkt/resque.git', :require => 'resque/server'

#mongodb related stuff
gem 'bson_ext'        , "~> 1.4"
gem 'mongoid'         , "~> 2.3.3"


# Declare your gem's dependencies in turducken.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

gem 'rturk'           , :git => "https://github.com/mdp/rturk.git", :branch => "3.0pre"

# jquery-rails is used by the dummy application
gem "jquery-rails"

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

group :test do
  gem 'database_cleaner' , '0.6.7'
  
  # fake rails app to run engine tests in.
  gem 'combustion', '~> 0.3.1'

  # mocks and fake data
  gem 'fabrication'      , '~> 1.2.0'
  gem 'faker'
  
  # test DSLs
  gem 'rspec'            , '~> 2.6.0'
  gem 'rspec-rails'      , '2.6.1'

  gem 'shoulda-matchers' , '~> 1.0.0'
  gem 'capybara'

  # Pretty printed test output  
  gem 'turn'             , :require => false

  gem 'vcr'
  gem 'webmock'          , '~> 1.7.7'
  gem 'crack'            , '>=0.1.7'
end
