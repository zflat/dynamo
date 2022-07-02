require_relative "artifact_helper"

class TestDynamoPlugin < ArtifactTest
  def test_plugin_lsit
    assert_artifact("plugin list")
  end
end
