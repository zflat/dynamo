module InspecPlugins
  module Init
    class Plugin < Inspec.plugin(2)
      plugin_name :'dynamo-init'

      cli_command :init do
        require_relative "dynamo-init/cli"
        InspecPlugins::Init::CLI
      end
    end
  end
end
