require "dynamo/errors"

module Dynamo
  module Plugin
    module V2
      class Exception < Dynamo::Error; end
      class ConfigError < Dynamo::Plugin::V2::Exception; end
      class LoadError < Dynamo::Plugin::V2::Exception; end

      class GemActionError < Dynamo::Plugin::V2::Exception
        attr_accessor :plugin_name
        attr_accessor :version
      end

      class InstallError < Dynamo::Plugin::V2::GemActionError; end

      class PluginExcludedError < Dynamo::Plugin::V2::InstallError
        attr_accessor :details
      end

      class UpdateError < Dynamo::Plugin::V2::GemActionError
        attr_accessor :from_version, :to_version
      end

      class UnInstallError < Dynamo::Plugin::V2::GemActionError; end
      class SearchError < Dynamo::Plugin::V2::GemActionError; end
    end
  end
end

require "dynamo/globals"
require "dynamo/plugin/v2/config_file"
require "dynamo/plugin/v2/registry"
require "dynamo/plugin/v2/loader"
require "dynamo/plugin/v2/plugin_base"

# Load all plugin type base classes
Dir.glob(File.join(__dir__, "v2", "plugin_types", "*.rb")).each { |file| require file }

module Dynamo
  # Provides the base class that plugin implementors should use.
  def self.plugin(version, plugin_type = nil)
    unless version == 2
      raise "Only plugins version 2 is supported!"
    end

    return Dynamo::Plugin::V2::PluginBase if plugin_type.nil?

    Dynamo::Plugin::V2::PluginBase.base_class_for_type(plugin_type)
  end
end
