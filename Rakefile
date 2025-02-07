#!/usr/bin/env rake

require "bundler"
require "bundler/gem_helper"
require "rake/testtask"
require "fileutils"

Bundler::GemHelper.install_tasks name: "dynamo-core"
# Bundler::GemHelper.install_tasks name: "dynamo"

def prompt(message)
  print(message)
  STDIN.gets.chomp
end


GLOBS = [
  "test/unit/**/*_test.rb",
  "test/functional/**/*_test.rb",
  "lib/plugins/dynamo-*/test/**/*_test.rb",
].freeze

# run tests
task default: %w{ test }
task test: %w{ test:default }

namespace :test do

  Rake::TestTask.new(:default) do |t|
    t.libs << "test"
    t.test_files = Dir[*GLOBS].sort
    t.warning = !!ENV["W"]
    t.verbose = !!ENV["V"] # default to off. the test commands are _huge_.
    t.ruby_opts = ["--dev"] if defined?(JRUBY_VERSION)
  end

  begin
    require "chefstyle"
    require "rubocop/rake_task"
    RuboCop::RakeTask.new(:lint) do |task|
      task.options += ["--display-cop-names", "--no-color", "--parallel"]
    end
  rescue LoadError
    puts "rubocop is not available. Install the rubocop gem to run the lint tests."
  end

  task :list do
    puts Dir[*GLOBS].sort
  end

  task :missing do
    missing = Dir["test/**/*"] - Dir[*GLOBS]

    missing.reject! { |f| ! File.file? f }
    missing.reject! { |f| f =~ %r{test/(integration|cookbooks)} }
    missing.reject! { |f| f =~ %r{test/fixtures} }
    missing.reject! { |f| f =~ /test.*helper/ }
    missing.reject! { |f| f =~ %r{test/docker} }

    puts missing.sort
  end

  # rubocop:disable Style/BlockDelimiters,Layout/ExtraSpacing,Lint/AssignmentInCondition

  def n_threads_run(n_workers, jobs)
    queue = Queue.new

    jobs.each do |job|
      queue << job
    end

    n_workers.times.map {
      queue << nil            # 1 quit value per thread
      Thread.new do
        while job = queue.pop # go until quit value
          yield job
        end
      end
    }.each(&:join)
  end

  task :parallel do
    n      = (ENV["K"] || 4).to_i
    lock   = Mutex.new
    passed = true

    tests = Dir[*GLOBS].sort
    tests.concat([nil] * (n - tests.size % n)) unless # square it up
      tests.size % 4 == 0

    jobs = tests.each_slice(n).to_a.transpose
    t0   = Time.now
    out  = Queue.new

    n_threads_run n, jobs do |job|
      job.compact!
      lock.synchronize do
        warn "Running #{job.size} files in a thread"
      end

      t1 = Time.now
      cmd = "bundle exec minitest #{job.join " "}"
      output = `#{cmd} 2>&1`
      t2 = Time.now - t1

      lock.synchronize do
        if $?.success?
          warn "Finished #{job.size} files successfully in %d seconds" % [t2]
        else
          passed = false
          warn "Finished #{job.size} files with failures in %d seconds" % [t2]
        end
      end

      out << "#{cmd}\n\n#{output}"
    end

    puts "done"
    puts

    out.length.times do
      puts out.shift
      puts
    end

    puts "Ran in %d seconds" % [ Time.now - t0 ]

    exit 1 unless passed
  end

  desc "Run test files in multiple threads"
  task :isolated do
    require "fileutils"

    # Only needed for local runs, not CI?
    FileUtils.rm_rf File.expand_path "~/.dynamo"
    FileUtils.rm_rf File.expand_path "~/.chef"

    # 3 seems to be the magic number... (tho not by that much)
    bad, good, n = {}, [], (ENV.delete("K") || 3).to_i
    t0 = Time.now

    tests = Dir[*GLOBS].sort

    n_threads_run n, tests do |path|
      output = `bundle exec ruby -Ilib -Itest #{path} 2>&1`

      if $?.success?
        $stderr.print "."
        good << path
      else
        $stderr.print "x"
        bad[path] = output
      end
    end

    puts "done"
    puts "Ran in %d seconds" % [ Time.now - t0 ]

    unless good.empty?
      puts
      puts "# Good tests:"
      good.sort.each do |path|
        puts path
      end
    end

    unless bad.empty?
      puts
      puts "# Bad tests:"
      bad.keys.each do |path|
        puts path
      end
      puts
      puts "# Bad Test Output:"
      bad.each do |path, output|
        puts
        puts "# #{path}:"
        puts output
      end
      exit 1
    end
  end

  Rake::TestTask.new(:functional) do |t|
    t.libs << "test"
    t.test_files = Dir.glob([
      "test/functional/**/*_test.rb",
      "lib/plugins/dynamo-*/test/functional/**/*_test.rb",
    ])
    t.warning = !!ENV["W"]
    t.verbose = !!ENV["V"] # default to off. the test commands are _huge_.
    t.ruby_opts = ["--dev"] if defined?(JRUBY_VERSION)
  end

  Rake::TestTask.new(:unit) do |t|
    t.libs << "test"
    t.test_files = Dir.glob([
      "test/unit/**/*_test.rb",
      "lib/plugins/dynamo-*/test/unit/**/*_test.rb",
    ])
    t.warning = !!ENV["W"]
    t.verbose = !!ENV["V"] # default to off. the test commands are _huge_.
    t.ruby_opts = ["--dev"] if defined?(JRUBY_VERSION)
  end

  task :kitchen, [:os] do |task, args|
    concurrency = ENV["CONCURRENCY"] || 1
    os = args[:os] || ENV["OS"] || ""
    ENV["DOCKER"] = "true" if ENV["docker"].nil?
    sh("bundle exec kitchen test -c #{concurrency} #{os}")
  end

  task :ssh, [:target] do |_t, args|
    tests_path = File.join(File.dirname(__FILE__), "test", "integration", "test", "integration", "default")
    key_files = ENV["key_files"] || File.join(ENV["HOME"], ".ssh", "id_rsa")

    sh_cmd =  "bin/dynamo exec #{tests_path}/"
    sh_cmd += ENV["test"] ? "#{ENV["test"]}_spec.rb" : "*"
    sh_cmd += " --sudo" unless args[:target].split("@")[0] == "root"
    sh_cmd += " -t ssh://#{args[:target]}"
    sh_cmd += " --key_files=#{key_files}"
    sh_cmd += " --format=#{ENV["format"]}" if ENV["format"]

    sh("sh", "-c", sh_cmd)
  end

  project_dir = File.dirname(__FILE__)

end

# Print the current version of this gem or update it.
#
# @param [Type] target the new version you want to set, or nil if you only want to show
def dynamo_version(target = nil)
  path = "lib/dynamo/version.rb"
  require_relative path.sub(/.rb$/, "")

  nu_version = target.nil? ? "" : " -> #{target}"
  puts "Dynamo: #{Dynamo::VERSION}#{nu_version}"

  unless target.nil?
    raw = File.read(path)
    nu = raw.sub(/VERSION.*/, "VERSION = '#{target}'.freeze")
    File.write(path, nu)
    load(path)
  end
end

# Check if a command is available
#
# @param [Type] x the command you are interested in
# @param [Type] msg the message to display if the command is missing
def require_command(x, msg = nil)
  return if system("command -v #{x} || exit 1")

  msg ||= "Please install it first!"
  puts "\033[31;1mCan't find command #{x.inspect}. #{msg}\033[0m"
  exit 1
end

# Check if a required environment variable has been set
#
# @param [String] x the variable you are interested in
# @param [String] msg the message you want to display if the variable is missing
def require_env(x, msg = nil)
  exists = `env | grep "^#{x}="`
  return unless exists.empty?

  puts "\033[31;1mCan't find environment variable #{x.inspect}. #{msg}\033[0m"
  exit 1
end

# Check the requirements for running an update of this repository.
def check_update_requirements
  require_command "git"
end

# Show the current version of this gem.
desc "Show the version of this gem"
task :version do
  dynamo_version
end
