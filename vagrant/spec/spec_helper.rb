require_relative '../slingshot.rb'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
