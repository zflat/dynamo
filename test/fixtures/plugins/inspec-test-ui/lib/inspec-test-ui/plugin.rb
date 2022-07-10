require "dynamo-test-ui/version"

module InspecPlugins
  module TestUI
    class Plugin < ::Inspec.plugin(2)
      plugin_name :'dynamo-test-ui'
      cli_command :testui do
        require "dynamo-test-ui/cli_command"
        InspecPlugins::TestUI::CliCommand
      end
    end
  end
end
