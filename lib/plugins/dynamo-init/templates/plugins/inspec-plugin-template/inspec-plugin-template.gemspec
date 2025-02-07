# As plugins are usually packaged and distributed as a RubyGem,
# we have to provide a .gemspec file, which controls the gembuild
# and publish process.  This is a fairly generic gemspec.

# It is traditional in a gemspec to dynamically load the current version
# from a file in the source tree.  The next three lines make that happen.
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "<%= plugin_name %>/version"

Gem::Specification.new do |spec|
  # Importantly, all Dynamo plugins must be prefixed with `dynamo-` (most
  # plugins) or other configured prefix.
  spec.name          = "<%= plugin_name %>"

  # It is polite to namespace your plugin under DynamoPlugins::YourPluginInCamelCase
  spec.version       = DynamoPlugins::<%= module_name %>::VERSION
  spec.authors       = ["<%= author_name %>"]
  spec.email         = ["<%= author_email %>"]
  spec.summary       = "<%= summary %>"
  spec.description   = "<%= description.is_a?(Array) ? description.join(" "): description %>"
  spec.homepage      = "<%= homepage %>"
  spec.license       = "<%= license_name %>"

  # Though complicated-looking, this is pretty standard for a gemspec.
  # It just filters what will actually be packaged in the gem (leaving
  # out tests, etc)
  spec.files = %w{
    README.md <%= snake_case %>.gemspec Gemfile
  } + Dir.glob(
    "lib/**/*", File::FNM_DOTMATCH
  ).reject { |f| File.directory?(f) }
  spec.require_paths = ["lib"]

  # If you rely on any other gems, list them here with any constraints.
  # This is how `dynamo plugin install` is able to manage your dependencies.
  # For example, perhaps you are writing a thing that talks to AWS, and you
  # want to ensure you have `aws-sdk` in a certain version.

  # All plugins should mention dynamo, > 2.2.78
  # 2.2.78 included the v2 Plugin API
  spec.add_dependency "dynamo", ">= 2.2.78", "< 4.0.0"
end
