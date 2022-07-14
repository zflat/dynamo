require "dynamo-test-ui/version"

module DynamoPlugins
  module TestUI
    class Plugin < ::Dynamo.plugin(2)
      plugin_name :'dynamo-test-ui'
      cli_command :testui do
        require "dynamo-test-ui/cli_command"
        DynamoPlugins::TestUI::CliCommand
      end
    end
  end
end
