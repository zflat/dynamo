lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "dynamo-test-fixture"
  spec.version       = "0.1.0"
  spec.authors       = ["Inspec core engineering team"]
  spec.email         = ["hello@test.test"]
  spec.license       = "Apache-2.0"

  spec.summary       = "Test plugin. Not intended for use as an example.".freeze
  spec.description   = "Test plugin. Not intended for use as an example.".freeze
  spec.homepage      = "https://homepage.test"

  spec.files         = %w{
    README.md
    LICENSE
    lib/dynamo-test-fixture.rb
    lib/dynamo-test-fixture/version.rb
    lib/dynamo-test-fixture/transport.rb
    lib/dynamo-test-fixture/connection.rb
    lib/dynamo-test-fixture/platform.rb
    dynamo-test-fixture.gemspec
  }
  spec.executables   = []
  spec.require_paths = ["lib"]

  # No deps
end
