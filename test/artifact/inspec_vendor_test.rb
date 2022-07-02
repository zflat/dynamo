require_relative "artifact_helper"

class TestDynamoVendor < ArtifactTest
  def test_vendor
    assert_artifact("vendor examples/profile --overwrite")
  end
end
