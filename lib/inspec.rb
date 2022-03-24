# copyright: 2015, Dominik Richter

libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require "inspec/version"
require "inspec/exceptions"
require "inspec/utils/deprecation"
require "inspec/shell"
require "inspec/globals"
require "inspec/utils/telemetry"
require "inspec/utils/telemetry/global_methods"

require "inspec/plugin/v2"

require "inspec/cli"
