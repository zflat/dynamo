source "https://rubygems.org"

gem "inspec-core", path: "."

gem "ffi", ">= 1.9.14", "!= 1.13.0", "!= 1.14.2"

if Gem.ruby_version.to_s.start_with?("2.5")
  # 16.7.23 required ruby 2.6+
  gem "chef-utils", "< 16.7.23" # TODO: remove when we drop ruby 2.5
end

# inspec tests depend text output that changed in the 3.10 release
# but our runtime dep is still 3.9+
gem "rspec", ">= 3.10"

group :omnibus do
  gem "rb-readline"
  gem "appbundler"
  gem "ed25519" # ed25519 ssh key support done here as its a native gem we can't put in the gemspec
  gem "bcrypt_pbkdf" # ed25519 ssh key support done here as its a native gem we can't put in the gemspec
end

group :test do
  gem "chefstyle", "~> 2.0.3"
  gem "concurrent-ruby", "~> 1.0"
  if Gem.ruby_version.to_s.start_with?("2.5")
    gem "html-proofer", "= 3.19.1" , platforms: :ruby # do not attempt to run proofer on windows
  else
    gem "html-proofer", platforms: :ruby # do not attempt to run proofer on windows
  end
  gem "json_schemer", ">= 0.2.1", "< 0.2.19"
  gem "m"
  gem "minitest-sprint", "~> 1.0"
  gem "minitest", "~> 5.5"
  gem "mocha", "~> 1.1"
  gem "nokogiri", "~> 1.9"
  gem "pry-byebug"
  gem "pry", "~> 0.10"
  gem "rake", ">= 10"
  gem "ruby-progressbar", "~> 1.8"
  gem "simplecov", "~> 0.18"
  gem "webmock", "~> 3.0"
end

group :deploy do
  gem "inquirer"
end

