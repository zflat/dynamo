require_relative "artifact_helper"

class TestDynamoEnv < ArtifactTest
  def test_env
    skip if windows?
    assert_artifact("env bash")
  end
end
