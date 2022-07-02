require_relative "artifact_helper"
require "open3"

class TestDynamoVersion < ArtifactTest
  def test_version
    assert_artifact(:version)
  end
end
