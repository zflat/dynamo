lib = File.expand_path("../lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require_relative "dynamo-test-fixture/version"
require_relative "dynamo-test-fixture/plugin"
