require "pathname" unless defined?(Pathname)
require_relative "renderer"

module DynamoPlugins
  module Init
    class CLI < Dynamo.plugin(2, :cli_command)
      subcommand_desc "init SUBCOMMAND", "Generate plugin code"

      TEMPLATES_PATH = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "templates"))

      require_relative "cli_plugin"
    end
  end
end
