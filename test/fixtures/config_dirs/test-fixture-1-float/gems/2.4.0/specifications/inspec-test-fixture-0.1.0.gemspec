# stub: dynamo-test-fixture 0.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "dynamo-test-fixture".freeze
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["test".freeze]
  s.date = "2018-08-17"
  s.description = "Test plugin. Not intended for use as an example.".freeze
  s.summary = "Test plugin. Not intended for use as an example.".freeze
  s.email = ["hello@test.test".freeze]
  s.homepage = "https://homepage.test".freeze
  s.rubygems_version = "2.6.13".freeze

  s.installed_by_version = "2.6.13" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new("1.2.0")
      s.add_development_dependency(%q{rake}.freeze, ["~> 10.0"])
    else
      s.add_dependency(%q{rake}.freeze, ["~> 10.0"])
    end
  else
    s.add_dependency(%q{rake}.freeze, ["~> 10.0"])
  end
end
