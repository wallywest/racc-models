ENV["RAILS_ENV"] ||= 'test'

if (ENV['COVERAGE'] == 'on')
  require 'simplecov'
  require 'simplecov-rcov'
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
end

require 'support'

require File.expand_path("../../config/environment", __FILE__)
require 'timecop'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true
  
  config.use_instantiated_fixtures  = false
  
  config.filter_run_excluding :exclude => true

  config.before(:all) do
    ThreadLocalHelper.thread_local_domain = nil
    ThreadLocalHelper.thread_local_app_id = nil
  end  

end

def login_with_super
end

def login_with role
end
