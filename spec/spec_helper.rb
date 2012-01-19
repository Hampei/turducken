SPEC_ROOT = File.expand_path(File.dirname(__FILE__)) unless defined? SPEC_ROOT

require 'rubygems'
require 'bundler'

Bundler.require :default, :development, :test

require 'capybara/rspec'
Combustion.initialize! :action_controller, :action_view
require 'rspec/rails'
require 'capybara/rails'
require 'webmock/rspec'

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

Turducken.setup(:worker_model => Worker, :callback_host => 'none')

# opts: :filename - name of file within fake_responses directory to return contents of. defaults to operation.underscore
#       :response - contents to return on the request. if specified, :filename is ignored.
def mock_turk_operation(operation, opts = {})
  filename = opts[:filename] || "#{operation.underscore}.xml"
  response = opts[:response] || File.read(File.join(SPEC_ROOT, 'fake_responses', filename))
  stub_request(:post, /amazonaws.com/).with(:body => /Operation=#{operation}/).to_return(:body => response)
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
# Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

Dir[File.join(SPEC_ROOT, "fabricators/*.rb")].each {|f| require f}

# VCR.config do |c|
#   c.cassette_library_dir = Rails.root.join("spec", "vcr")
#   c.stub_with :webmock # or :fakeweb
#   c.default_cassette_options = { :record => :once }
# end

RSpec.configure do |config|
  config.mock_with :rspec

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.orm = "mongoid"
  end

  config.before(:each) do
    DatabaseCleaner.start
    Resque.inline = false
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
