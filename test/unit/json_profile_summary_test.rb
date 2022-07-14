# copyright: 2020, Chef Software Inc.

require "helper"
require "dynamo/utils/json_profile_summary"

describe "JsoneProfileSummary" do
  let(:profile_summary) { Dynamo::Utils::JsonProfileSummary }
  let(:info) { { test: "information" } }

  describe "writes JSON to file" do
    it "writes json to file" do
      Dir.mktmpdir do |dir|
        profile_summary.produce_json(
          info: info,
          write_path: "#{dir}/dynamo-test.json"
        )
        assert File.file?("#{dir}/dynamo-test.json")
      end
    end

    it "suppresses loading output if requested" do
      Dir.mktmpdir do |dir|
        assert_output("") {
          profile_summary.produce_json(
            info: info,
            write_path: "#{dir}/dynamo-test.json",
            suppress_output: true
          )
        }
      end
    end

    it "returns JSON to STDOUT if no dst" do
      assert_output(
        "{\"test\":\"information\",\"generator\":{\"name\":\"dynamo\",\""\
        "version\":\"#{Dynamo::VERSION}\"}}\n"
      ) { profile_summary.produce_json(info: info) }
    end

    it "fails without arguments" do
      assert_raises(ArgumentError) { profile_summary.produce_json }
    end
  end
end
