require_relative "artifact_helper"

class TestDynamoJson < ArtifactTest
  def test_json
    assert_artifact("json examples/profile")
  end
end
