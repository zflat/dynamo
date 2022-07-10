require "dynamo-reporter-test-fixture/version"

module InspecPlugins
  module ReporterTestFixture
    class Plugin < ::Inspec.plugin(2)
      plugin_name :'dynamo-reporter-test-fixture'
      reporter :"test-fixture" do
        require "dynamo-reporter-test-fixture/reporter"
        InspecPlugins::ReporterTestFixture::ReporterImplementation
      end
    end
  end
end
