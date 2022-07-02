module DynamoPlugins
  module TestFixture

    class Plugin < Dynamo.plugin(2)
      plugin_name :'dynamo-test-fixture'

      mock_plugin_type :'dynamo-test-fixture' do
        require_relative 'mock_plugin'
        DynamoPlugins::TestFixture
      end
    end
  end
end
