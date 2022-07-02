lib = File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'dynamo-test-fixture/version'
require 'dynamo-test-fixture/plugin'
