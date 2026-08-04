ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include FactoryBot::Syntax::Methods

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  include FactoryBot::Syntax::Methods

  def auth_headers(user)
    { "Authorization" => "Bearer #{user.api_token}" }
  end
end
