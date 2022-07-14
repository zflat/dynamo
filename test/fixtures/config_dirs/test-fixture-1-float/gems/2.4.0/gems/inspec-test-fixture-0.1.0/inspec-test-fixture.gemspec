lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dynamo-test-fixture/version"

Gem::Specification.new do |spec|
  spec.name          = "dynamo-test-fixture"
  spec.version       = "0.1.0"
  spec.authors       = ["Dynamo Engineering Team"]
  spec.email         = ["hello@test.test"]

  spec.summary       = %q{A simple test plugin gem for InSpec}
  spec.description   = %q{This gem is used to test the gem search and install capabilities of InSpec's plugin V2 system.  It is not a good example or starting point for plugin development.}
  spec.homepage      = "https://github.com/inspec/inspec"

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
end
