# Copyright 2015 Dominik Richter

require "inspec/utils/deprecation/deprecator"
require "inspec/dist"
require "inspec/utils/json_profile_summary"

module Inspec # TODO: move this somewhere "better"?
  autoload :BaseCLI,       "inspec/base_cli"
  autoload :Deprecation,   "inspec/utils/deprecation"
  autoload :Exceptions,    "inspec/exceptions"
  autoload :EnvPrinter,    "inspec/env_printer"
  autoload :Fetcher,       "inspec/fetcher"
  autoload :Formatters,    "inspec/formatters"
  autoload :Globals,       "inspec/globals"
  autoload :Impact,        "inspec/impact"
  autoload :Impact,        "inspec/impact"
  autoload :InputRegistry, "inspec/input_registry"
  autoload :Profile,       "inspec/profile"
  autoload :Reporters,     "inspec/reporters"
  autoload :Resource,      "inspec/resource"
  autoload :Rule,          "inspec/rule"
  autoload :Runner,        "inspec/runner"
  autoload :Runner,        "inspec/runner"
  autoload :Shell,         "inspec/shell"
  autoload :SourceReader,  "inspec/source_reader"
  autoload :Telemetry,     "inspec/utils/telemetry"
  autoload :V2,            "inspec/plugin/v2"
  autoload :VERSION,       "inspec/version"
end

class Inspec::InspecCLI < Inspec::BaseCLI
  class_option :log_level, aliases: :l, type: :string,
               desc: "Set the log level: info (default), debug, warn, error"

  class_option :log_location, type: :string,
               desc: "Location to send diagnostic log messages to. (default: $stdout or Inspec::Log.error)"

  class_option :diagnose, type: :boolean,
    desc: "Show diagnostics (versions, configurations)"

  class_option :color, type: :boolean,
    desc: "Use colors in output."

  class_option :interactive, type: :boolean,
    desc: "Allow or disable user interaction"

  class_option :disable_core_plugins, type: :string, banner: "", # Actually a boolean, but this suppresses the creation of a --no-disable...
    desc: "Disable loading all plugins that are shipped in the lib/plugins directory of InSpec. Useful in development.",
    hide: true

  class_option :disable_user_plugins, type: :string, banner: "",
    desc: "Disable loading all plugins that the user installed."

  desc "env", "Output shell-appropriate completion configuration"
  def env(shell = nil)
    p = Inspec::EnvPrinter.new(self.class, shell)
    p.print_and_exit!
  rescue StandardError => e
    pretty_handle_exception(e)
  end

  desc "version", "prints the version of this tool"
  option :format, type: :string
  def version
    if config["format"] == "json"
      v = { version: Inspec::VERSION }
      puts v.to_json
    else
      puts Inspec::VERSION
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
require "inspec/plugin/v2"

begin
  # Load v2 plugins.  Manually check for plugin disablement.
  omit_core = ARGV.delete("--disable-core-plugins")
  omit_user = ARGV.delete("--disable-user-plugins")
  v2_loader = Inspec::Plugin::V2::Loader.new(omit_core_plugins: omit_core, omit_user_plugins: omit_user)
  v2_loader.load_all
  v2_loader.exit_on_load_error
  v2_loader.activate_mentioned_cli_plugins

rescue Inspec::Plugin::V2::Exception => v2ex
  Inspec::Log.error v2ex.message

  if ARGV.include?("--debug")
    Inspec::Log.error v2ex.class.name
    Inspec::Log.error v2ex.backtrace.join("\n")
  else
    Inspec::Log.error "Run again with --debug for a stacktrace."
  end
  exit Inspec::UI::EXIT_PLUGIN_ERROR
end
