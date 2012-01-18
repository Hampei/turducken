SPEC_ROOT = File.expand_path(File.dirname(__FILE__)) unless defined? SPEC_ROOT

require 'rubygems'
require 'bundler'

Bundler.require :default, :development, :test

require 'capybara/rspec'
Combustion.initialize! :action_controller, :action_view
require 'rspec/rails'
require 'capybara/rails'

# RSpec.configure do |config|
#   config.use_transactional_fixtures = true
# end

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
# require 'rspec'
require 'vcr'
require 'yaml'

require 'rturk'
require 'turducken'




Dir.glob(File.join(File.dirname(__FILE__), '..', 'app', '**/*.rb')).each {|f| require f }


@aws = YAML.load(File.open(File.join(SPEC_ROOT, 'aws.yml')))
RTurk.setup(@aws['AWSAccessKeyId'], @aws['AWSAccessKey'], :sandbox => true)

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
# Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
# Dir[Rails.root.join("spec/fabricators/**/*.rb")].each {|f| require f}

# VCR.config do |c|
#   c.cassette_library_dir = Rails.root.join("spec", "vcr")
#   c.stub_with :webmock # or :fakeweb
#   c.default_cassette_options = { :record => :once }
# end

RSpec.configure do |config|
  # == Mock Framework
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.orm = "mongoid"
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
  
  #wrap tests with VCR
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.around(:each, :vcr) do |example|
    name = example.metadata[:full_description].split(/\s+/, 2).join("/").underscore.gsub(/[^\w\/]+/, "_")
    options = example.metadata.slice(:record, :match_requests_on).except(:example_group)
    VCR.use_cassette(name, options) { example.call }
  end

end
