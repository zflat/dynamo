require "functional/helper"

describe "command tests" do
  include FunctionalHelper

  describe "version" do
    it "provides the version number on stdout" do
      out = dynamo("version")

      _(out.stdout).must_equal Dynamo::VERSION + "\n"
      _(out.stderr).must_equal ""

      assert_exit_code 0, out
    end

    it "prints the version as JSON when the format is specified as JSON" do
      out = dynamo("version --format=json")

      _(out.stdout).must_equal %({"version":"#{Dynamo::VERSION}"}\n)

      _(out.stderr).must_equal ""

      assert_exit_code 0, out
    end
  end

  describe "help" do
    let(:outputs) do
      [
        dynamo("help").stdout,
        dynamo("--help").stdout,
        dynamo("").stdout,
      ]
    end

    it "outputs the same message regardless of invocation" do
      _(outputs.uniq.length).must_equal 1
    end

    it "outputs both core commands and v2 CLI plugins" do
      commands = %w{
        env
        help
        init
        plugin
        version
      }
      outputs.each do |output|
        commands.each do |subcommand|
          _(output).must_include(subcommand)
        end
      end
    end

    it "has an About section" do
      outputs.each do |output|
        _(output).must_include("About")
      end
    end
  end
end
