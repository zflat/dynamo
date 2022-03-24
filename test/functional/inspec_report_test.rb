require "functional/helper"

describe "inspec report tests" do
  include FunctionalHelper

  describe "report" do
    it "loads a json report" do
      o = { "reporter" => ["json"], "report" => true }
      runner = ::Inspec::Runner.new(o)
      runner.add_target(example_profile)
      runner.run
      _(runner.report.count).must_equal 4
      _(runner.report.inspect).must_include ':title=>"InSpec Example Profile"'
      _(runner.report.inspect).must_include ':status=>"passed"'
    end

    # Due to the way we require/use rspec, you can only run one runner.
    # You have to reload rspec to run another.
  end
end
