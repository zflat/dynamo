module DynamoPlugins
  module Init
    class Plugin < Dynamo.plugin(2)
      plugin_name :'dynamo-init'

      cli_command :init do
        require_relative "dynamo-init/cli"
        DynamoPlugins::Init::CLI
      end
    end
  end
end
