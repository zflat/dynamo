require "dynamo/utils/telemetry"
require "helper"

class TestTelemetryGlobalMethods < Minitest::Test
  def setup
    @collector = Dynamo::Telemetry::Collector.instance
    @collector.load_config(Dynamo::Config.mock("enable_telemetry" => true))
    @collector.reset!
  end

  def test_record_telemetry_data
    assert Dynamo.record_telemetry_data(:deprecation_group, "serverspec_compat")

    depgrp = @collector.find_or_create_data_series(:deprecation_group)
    assert_equal ["serverspec_compat"], depgrp.data
    assert_equal :deprecation_group, depgrp.name
  end

  def test_record_telemetry_data_with_block
    Dynamo.record_telemetry_data(:deprecation_group) do
      "serverspec_compat"
    end

    depgrp = @collector.find_or_create_data_series(:deprecation_group)
    assert_equal ["serverspec_compat"], depgrp.data
    assert_equal :deprecation_group, depgrp.name
  end

  def test_telemetry_disabled
    @collector.load_config(Dynamo::Config.mock(telemetry: false))
    refute Dynamo.record_telemetry_data(:deprecation_group, "serverspec_compat")
  end
end
