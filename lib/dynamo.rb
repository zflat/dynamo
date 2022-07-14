# copyright: 2015, Dominik Richter

libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require "dynamo/version"
require "dynamo/exceptions"
require "dynamo/utils/deprecation"
require "dynamo/shell"
require "dynamo/globals"
require "dynamo/utils/telemetry"
require "dynamo/utils/telemetry/global_methods"

require "dynamo/plugin/v2"

require "dynamo/cli"
