# coding: utf-8
require "helper"

class Module
  include Minitest::Spec::DSL
end

module FunctionalHelper
  extend Minitest::Spec::DSL
  extend Minitest::Guard

  let(:repo_path) do
    path = File.expand_path("../..", __dir__)
    # fix for vagrant repo pathing
    path.gsub!("//vboxsvr", "C:") if is_windows?
    path
  end
  let(:inspec_path) { File.join(repo_path, "inspec-bin", "bin", "inspec") }
  libdir = File.expand_path "lib"
  let(:exec_inspec) { [Gem.ruby, "-I#{libdir}", inspec_path].join " " }
  let(:mock_path) { File.join(repo_path, "test", "fixtures") }
  let(:profile_path) { File.join(mock_path, "profiles") }
  let(:examples_path) { File.join(profile_path, "old-examples") }
  let(:integration_test_path) { File.join(repo_path, "test", "integration", "default") }
  let(:all_profiles) { Dir.glob("#{profile_path}/**/inspec.yml") }
  let(:all_profile_folders) { all_profiles.map { |path| File.dirname(path) } }

  let(:complete_profile) { "#{profile_path}/complete-profile" }
  let(:example_profile) { File.join(examples_path, "profile") }
  let(:meta_profile) { File.join(examples_path, "meta-profile") }
  let(:example_control) { File.join(example_profile, "controls", "example-tmp.rb") }
  let(:inheritance_profile) { File.join(examples_path, "inheritance") }
  let(:shell_inheritance_profile) { File.join(repo_path, "test", "fixtures", "profiles", "dependencies", "shell-inheritance") }
  let(:failure_control) { File.join(profile_path, "failures", "controls", "failures.rb") }
  let(:simple_inheritance) { File.join(profile_path, "simple-inheritance") }
  let(:sensitive_profile) { File.join(examples_path, "profile-sensitive") }
  let(:config_dir_path) { File.join(mock_path, "config_dirs") }

  let(:dst) do
    # create a temporary path, but we only want an auto-clean helper
    # so remove the file and give back the path
    res = Tempfile.new("inspec-shred")
    res.close
    FileUtils.rm(res.path)
    TMP_CACHE[res.path] = res
  end

  root_dir = windows? ? "C:" : "/etc"
  ROOT_LICENSE_PATH = "#{root_dir}/chef/accepted_licenses/inspec".freeze

  def assert_exit_code(exp, cmd)
    exp = 1 if windows? && (exp != 0)
    assert_equal exp, cmd.exit_status
  end

  def convert_windows_output(text)
    text = text.force_encoding("UTF-8")
    text.gsub!("[PASS]", "✔")
    text.gsub!("\033[0;1;32m", "\033[38;5;41m")
    text.gsub!("[SKIP]", "↺")
    text.gsub!("\033[0;37m", "\033[38;5;247m")
    text.gsub!("[FAIL]", "×")
    text.gsub!("\033[0;1;31m", "\033[38;5;9m")
  end

  def self.is_windows?
    RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/
  end

  def is_windows?
    FunctionalHelper.is_windows?
  end

  def stderr_ignore_deprecations(result)
    stderr = result.stderr
    suffix = stderr.end_with?("\n") ? "\n" : ""
    stderr.split("\n").reject { |l| l.include? " DEPRECATION: " }.join("\n") + suffix
  end

  def assert_json_controls_passing(_result = nil) # dummy arg
    # Strategy: assemble an array of tests that failed or skipped, and insist it is empty
    # @json['profiles'][0]['controls'][0]['results'][0]['status']
    failed_tests = []
    @json["profiles"].each do |profile_struct|
      profile_name = profile_struct["name"]
      profile_struct["controls"].each do |control_struct|
        control_name = control_struct["id"]
        control_struct["results"].compact.each do |test_struct|
          test_desc = test_struct["code_desc"]
          if test_struct["status"] != "passed"
            failed_tests << "#{profile_name}/#{control_name}/#{test_desc}"
          end
        end
      end
    end

    _(failed_tests).must_be_empty
  end

  @inspec_mutex ||= Mutex.new

  def self.inspec_mutex
    @inspec_mutex
  end

  def self.inspec_cache
    @inspec_cache ||= {}
  end

  def inspec_cache
    FunctionalHelper.inspec_cache
  end

  def inspec_mutex
    FunctionalHelper.inspec_mutex
  end

  def inspec(commandline, prefix = nil)
    run_cmd "#{exec_inspec} #{commandline}", prefix
  end

  def inspec_with_env(commandline, env = {})
    inspec(commandline, assemble_env_prefix(env))
  end

  # Copy all examples to a temporary directory for functional tests.
  # You can provide an optional directory which will be handed to your
  # test block with its absolute path. If nothing is provided you will
  # get the path of the examples directory in the tmp environment.
  #
  # @param dir = nil [String] optional directory you want to test
  # @param &block [Type] actual test block
  def prepare_examples(dir = nil, &block)
    Dir.mktmpdir do |tmpdir|
      FileUtils.cp_r(examples_path, tmpdir)
      bn = File.basename(examples_path)
      yield(File.join(tmpdir, bn, dir.to_s))
    end
  end

  private

  def assemble_env_prefix(env = {})
    if is_windows?
      env_prefix = env.to_a.map { |assignment| "set #{assignment[0]}=#{assignment[1]}" }.join("&& ")
      env_prefix += "&& " unless env_prefix.empty?
    else
      env_prefix = env.to_a.map { |assignment| "#{assignment[0]}=#{assignment[1]}" }.join(" ")
      env_prefix += " "
    end
    env_prefix
  end
end

#=========================================================================================#
#                                Plugin Support
#=========================================================================================#
module PluginFunctionalHelper
  include FunctionalHelper

  def run_inspec_with_plugin(command, opts)
    pre = Proc.new do |tmp_dir|
      content = JSON.generate(__make_plugin_file_data_structure_with_path(opts[:plugin_path]))
      File.write(File.join(tmp_dir, "plugins.json"), content)
    end

    opts = {
      pre_run: pre,
      tmpdir: true,
      json: true,
      env: {
        "INSPEC_CONFIG_DIR" => ".", # We're in tmpdir
      },
    }.merge(opts)
    run_inspec_process(command, opts)
  end

  def __make_plugin_file_data_structure_with_path(path)
    # TODO: dry this up, refs #3350
    plugin_name = File.basename(path, ".rb")
    data = __make_empty_plugin_file_data_structure
    data["plugins"] << {
      "name" => plugin_name,
      "installation_type" => "path",
      "installation_path" => path,
    }
    data
  end

  def __make_empty_plugin_file_data_structure
    # TODO: dry this up, refs #3350
    {
      "plugins_config_version" => "1.0.0",
      "plugins" => [],
    }
  end
end
