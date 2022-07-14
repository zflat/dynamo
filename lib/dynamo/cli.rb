# Copyright 2015 Dominik Richter

require "dynamo/utils/deprecation/deprecator"
require "dynamo/dist"
require "dynamo/utils/json_profile_summary"

module Dynamo # TODO: move this somewhere "better"?
  autoload :BaseCLI,       "dynamo/base_cli"
  autoload :Deprecation,   "dynamo/utils/deprecation"
  autoload :Exceptions,    "dynamo/exceptions"
  autoload :EnvPrinter,    "dynamo/env_printer"
  autoload :Fetcher,       "dynamo/fetcher"
  autoload :Formatters,    "dynamo/formatters"
  autoload :Globals,       "dynamo/globals"
  autoload :Impact,        "dynamo/impact"
  autoload :Impact,        "dynamo/impact"
  autoload :InputRegistry, "dynamo/input_registry"
  autoload :Profile,       "dynamo/profile"
  autoload :Reporters,     "dynamo/reporters"
  autoload :Resource,      "dynamo/resource"
  autoload :Rule,          "dynamo/rule"
  autoload :Runner,        "dynamo/runner"
  autoload :Runner,        "dynamo/runner"
  autoload :Shell,         "dynamo/shell"
  autoload :SourceReader,  "dynamo/source_reader"
  autoload :Telemetry,     "dynamo/utils/telemetry"
  autoload :V2,            "dynamo/plugin/v2"
  autoload :VERSION,       "dynamo/version"
end

class Dynamo::DynamoCLI < Dynamo::BaseCLI
  class_option :log_level, aliases: :l, type: :string,
               desc: "Set the log level: info (default), debug, warn, error"

  class_option :log_location, type: :string,
               desc: "Location to send diagnostic log messages to. (default: $stdout or Dynamo::Log.error)"

  class_option :diagnose, type: :boolean,
    desc: "Show diagnostics (versions, configurations)"

  class_option :color, type: :boolean,
    desc: "Use colors in output."

  class_option :interactive, type: :boolean,
    desc: "Allow or disable user interaction"

  class_option :disable_core_plugins, type: :string, banner: "", # Actually a boolean, but this suppresses the creation of a --no-disable...
    desc: "Disable loading all plugins that are shipped in the lib/plugins directory of Dynamo. Useful in development.",
    hide: true

  class_option :disable_user_plugins, type: :string, banner: "",
    desc: "Disable loading all plugins that the user installed."

  desc "env", "Output shell-appropriate completion configuration"
  def env(shell = nil)
    p = Dynamo::EnvPrinter.new(self.class, shell)
    p.print_and_exit!
  rescue StandardError => e
    pretty_handle_exception(e)
  end

  desc "version", "prints the version of this tool"
  option :format, type: :string
  def version
    if config["format"] == "json"
      v = { version: Dynamo::VERSION }
      puts v.to_json
    else
      puts Dynamo::VERSION
    end
  end
  map %w{-v --version} => :version

end

#=====================================================================#
#                        Pre-Flight Code
#=====================================================================#

help_commands = ["-h", "--help", "help"]

#---------------------------------------------------------------------#
# Adjustments for help handling
# This allows you to use any of the normal help commands after the normal args.
#---------------------------------------------------------------------#
(help_commands & ARGV).each do |cmd|
  # move the help argument to one place behind the end for Thor to digest
  if ARGV.size > 1
    match = ARGV.delete(cmd)
    ARGV.insert(-2, match)
  end
end

#---------------------------------------------------------------------#
# Plugin Loading
#---------------------------------------------------------------------#
require "dynamo/plugin/v2"

begin
  # Load v2 plugins.  Manually check for plugin disablement.
  omit_core = ARGV.delete("--disable-core-plugins")
  omit_user = ARGV.delete("--disable-user-plugins")
  v2_loader = Dynamo::Plugin::V2::Loader.new(omit_core_plugins: omit_core, omit_user_plugins: omit_user)
  v2_loader.load_all
  v2_loader.exit_on_load_error
  v2_loader.activate_mentioned_cli_plugins

rescue Dynamo::Plugin::V2::Exception => v2ex
  Dynamo::Log.error v2ex.message

  if ARGV.include?("--debug")
    Dynamo::Log.error v2ex.class.name
    Dynamo::Log.error v2ex.backtrace.join("\n")
  else
    Dynamo::Log.error "Run again with --debug for a stacktrace."
  end
  exit Dynamo::UI::EXIT_PLUGIN_ERROR
end
