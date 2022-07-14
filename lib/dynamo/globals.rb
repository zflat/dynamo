require_relative "utils/install_context"

module Dynamo
  extend Dynamo::InstallContextHelpers

  def self.config_dir
    ENV["DYNAMO_CONFIG_DIR"] || File.join(home_path, ".dynamo")
  end

  def self.src_root
    @src_root ||= File.expand_path(File.join(__FILE__, "../../.."))
  end

  def self.home_path
    Dir.home
  rescue ArgumentError, NoMethodError
    # If ENV['HOME'] is not set, Dir.home will fail due to expanding the ~. Fallback to Etc.
    require "etc" unless defined?(Etc)
    Etc.getpwuid.dir
  end
end
