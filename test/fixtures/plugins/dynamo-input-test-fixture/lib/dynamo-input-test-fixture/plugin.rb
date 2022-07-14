require "inspec-input-test-fixture/version"

module DynamoPlugins
  module InputTestFixture
    class Plugin < ::Dynamo.plugin(2)
      plugin_name :'inspec-input-test-fixture'
      input :test_fixture do
        require "inspec-input-test-fixture/input"
        DynamoPlugins::InputTestFixture::InputImplementation
      end
    end
  end
end
