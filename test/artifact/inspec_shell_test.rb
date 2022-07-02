require_relative "artifact_helper"

class TestDynamoShell < ArtifactTest
  def test_shell
    assert_artifact("shell -c 'os.family'")
  end
end
