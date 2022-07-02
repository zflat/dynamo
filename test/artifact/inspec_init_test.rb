require_relative "artifact_helper"

class TestDynamoInit < ArtifactTest
  def test_init_profile
    assert_artifact("init profile dynamo-profile")
  end

  def test_init_plugin
    assert_artifact("init plugin dynamo-plugin --no-prompt")
  end
end
