require "dynamo-reporter-test-fixture/version"

module DynamoPlugins
  module ReporterTestFixture
    class Plugin < ::Dynamo.plugin(2)
      plugin_name :'dynamo-reporter-test-fixture'
      reporter :"test-fixture" do
        require "dynamo-reporter-test-fixture/reporter"
        DynamoPlugins::ReporterTestFixture::ReporterImplementation
      end
    end
  end
end
