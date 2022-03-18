# copyright: 2015, Dominik Richter

libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require "inspec/version"
require "inspec/exceptions"
require "inspec/utils/deprecation"
require "matchers/matchers"
require "inspec/shell"
require "inspec/formatters"
require "inspec/reporters"
require "inspec/rspec_extensions"
require "inspec/globals"
require "inspec/impact"
require "inspec/utils/telemetry"
require "inspec/utils/telemetry/global_methods"

require "inspec/plugin/v2"

require "inspec/cli"

# More things to strip away
#require "inspec/rule"
#require "inspec/runner"
#require "inspec/input_registry"
#require "inspec/fetcher"
#require "inspec/source_reader"
