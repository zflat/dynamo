lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dynamo-test-fixture/version"

Gem::Specification.new do |spec|
  spec.name          = "dynamo-test-fixture"
  spec.version       = DynamoPlugins::TestFixture::VERSION
  spec.authors       = ["test"]
  spec.email         = ["hello@test.test"]

  spec.summary       = "Test plugin. Not intended for use as an example.".freeze
  spec.description   = "Test plugin. Not intended for use as an example.".freeze
  spec.homepage      = "https://homepage.test"

  spec.files         = [
    "dynamo-test-fixture.gemspec",
    "lib/dynamo-test-fixture.rb",
    "lib/dynamo-test-fixture/plugin.rb",
    "lib/dynamo-test-fixture/mock_plugin.rb",
    "lib/dynamo-test-fixture/version.rb",
  ]
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 10.0"
  if DynamoPlugins::TestFixture::VERSION == "0.2.0"
    spec.add_dependency "ordinal_array", "~> 0.2.0"
  end
end
