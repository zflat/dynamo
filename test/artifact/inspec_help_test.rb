require_relative "artifact_helper"

class TestDynamoHelp < ArtifactTest
  def test_help
    assert_artifact(:help)
  end
end
