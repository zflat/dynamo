lib = File.expand_path("../lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require_relative "dynamo-dsl-test/version"
require_relative "dynamo-dsl-test/plugin"
