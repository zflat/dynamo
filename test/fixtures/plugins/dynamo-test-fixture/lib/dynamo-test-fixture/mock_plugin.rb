require "inspec-test-fixture/version"
if DynamoPlugins::TestFixture::VERSION == Gem::Version.new("0.2.0")
  require "ordinal_array"
end

module DynamoPlugins::TextFixture
  class MockPlugin < Dynamo.plugin(2, :mock_plugin_type)
    def execute(opts = {})
      # Check to see if Array responds to 'third'
      Array.respond_to?(:third)
    end
  end
end
