# Functional tests related to plugin facility
require "functional/helper"

# I wrapped the whole file in a describe to refactor the include and
# add parallelization. I didn't want to reindent the whole file until
# we know this works well.

# rubocop:disable Layout/IndentationConsistency

describe "plugins" do
  include FunctionalHelper
  parallelize_me!

#=========================================================================================#
#                                Loader Errors
#=========================================================================================#
describe "plugin loader" do
  it "handles an unloadable plugin correctly" do
    outcome = dynamo_with_env("version", INSPEC_CONFIG_DIR: File.join(config_dir_path, "plugin_error_on_load"))

    _(outcome.stdout).must_include("ERROR", "Have an error on stdout")
    _(outcome.stdout).must_include("Could not load plugin dynamo-divide-by-zero", "Name the plugin in the stdout error")
    _(outcome.stdout).wont_include("ZeroDivisionError", "No stacktrace in error by default")
    _(outcome.stdout).must_include("Errors were encountered while loading plugins", "Friendly message in error")
    _(outcome.stdout).must_include("Plugin name: dynamo-divide-by-zero", "Plugin named in error")
    _(outcome.stdout).must_include("divided by 0", "Exception message in error")

    assert_exit_code 2, outcome

    # TODO: split
    outcome = dynamo_with_env("version --debug", INSPEC_CONFIG_DIR: File.join(config_dir_path, "plugin_error_on_load"))

    _(outcome.stdout).must_include("ZeroDivisionError", "Include stacktrace in error with --debug")

    assert_exit_code 2, outcome
  end
end

#=========================================================================================#
#                              Disabling Plugins
#=========================================================================================#
describe "when disabling plugins" do
  describe "when disabling the core plugins" do
    it "should not be able to use core-provided commands" do
      run_result = run_dynamo_process("--disable-core-plugins habitat")
      _(run_result.stderr).must_include 'Could not find command "habitat".'

      # One might think that this should be code 2 (plugin error)
      # But because the core plugins are not loaded, 'habitat' is not
      # a known command, which makes it a usage error, code 1.
      assert_exit_code 1, run_result
    end
  end

  describe "when disabling the user plugins" do
    it "should not be able to use user commands" do
      run_result = run_dynamo_process("--disable-user-plugins meaningoflife answer", env: { INSPEC_CONFIG_DIR: File.join(config_dir_path, "meaning_by_path") })

      _(run_result.stderr).must_include 'Could not find command "meaningoflife"'

      assert_exit_code 1, run_result
    end
  end
end

#=========================================================================================#
#                           CliCommand plugin type
#=========================================================================================#
describe "cli command plugins" do
  it "is able to respond to a plugin-based cli subcommand" do
    outcome = dynamo_with_env("meaningoflife answer", INSPEC_CONFIG_DIR: File.join(config_dir_path, "meaning_by_path"))

    _(outcome.stderr).wont_include 'Could not find command "meaningoflife"'
    _(outcome.stderr).must_equal ""

    _(outcome.stdout).must_equal ""

    assert_exit_code 42, outcome
  end

  it "is able to respond to [help subcommand] invocations" do
    outcome = dynamo_with_env("help meaningoflife", INSPEC_CONFIG_DIR: File.join(config_dir_path, "meaning_by_path"))

    _(outcome.stderr).must_equal ""

    _(outcome.stdout).must_include "dynamo meaningoflife answer"
    # Full text:
    # 'Exits immediately with an exit code reflecting the answer to life the universe, and everything.'
    # but Thor will ellipsify based on the terminal width
    _(outcome.stdout).must_include "Exits immediately"

    assert_exit_code 0, outcome
  end

  # This is an important test; usually CLI plugins are only activated when their name is present in ARGV
  it "includes plugin-based cli commands in top-level help" do
    outcome = dynamo_with_env("help", INSPEC_CONFIG_DIR: File.join(config_dir_path, "meaning_by_path"))

    _(outcome.stdout).must_include "dynamo meaningoflife"

    assert_exit_code 0, outcome
  end
end

#=========================================================================================#
#                             Input plugin type
#=========================================================================================#
describe "input plugins" do
  let(:env) { { INSPEC_CONFIG_DIR: "#{config_dir_path}/input_plugin" } }
  let(:profile) { "#{profile_path}/inputs/plugin" }
  def run_input_plugin_test_with_controls(controls)
    cmd = "exec #{profile} --controls #{controls}"
    run_result = run_dynamo_process(cmd, json: true, env: env)
    assert_json_controls_passing(run_result)
    _(run_result.stderr).must_be_empty
  end

  describe "when an input is provided only by a plugin" do
    it "should find the value" do
      run_input_plugin_test_with_controls("only_in_plugin")
    end
  end

  describe "when an input is provided both inline and by a higher-precedence plugin" do
    it "should use the value from the plugin" do
      run_input_plugin_test_with_controls("collide_plugin_higher")
    end
  end

  describe "when an input is provided both inline and by a lower-precedence plugin" do
    it "should use the value from inline" do
      run_input_plugin_test_with_controls("collide_inline_higher")
    end
  end

  describe "when examining the event log" do
    it "should include the expected events" do
      run_input_plugin_test_with_controls("event_log")
    end
  end

  describe "when listing available inputs" do
    it "should list available inputs" do
      run_input_plugin_test_with_controls("list_events")
    end
  end
end

#=========================================================================================#
#                           dynamo plugin command
#=========================================================================================#
# See lib/plugins/dynamo-plugin-manager-cli/test

#=========================================================================================#
#                                Plugin Disable Messaging
#=========================================================================================#
describe "disable plugin usage message integration" do
  it "mentions the --disable-user-plugins option" do
    outcome = dynamo("help")
    _(outcome.stdout).must_include("--disable-user-plugins")
  end
end


end
