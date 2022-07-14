module DynamoPlugins
  module TestFixture

    class Plugin < Dynamo.plugin(2)
      plugin_name :'inspec-test-fixture'

      mock_plugin_type :'inspec-test-fixture' do
        require_relative "mock_plugin"
        DynamoPlugins::TestFixture
      end
    end
  end
end
