require "dynamo/log"
require "dynamo/version"
require "dynamo/plugin/v2/config_file"
require "dynamo/plugin/v2/filter"

module Dynamo::Plugin::V2
  class Loader
    PREFIX = "dynamo".freeze
    attr_reader :conf_file, :registry, :options

    # For {dynamo}_plugin_name?
    include Dynamo::Plugin::V2::FilterPredicates
    extend Dynamo::Plugin::V2::FilterPredicates

    def initialize(options = {})
      @options = options
      @registry = Dynamo::Plugin::V2::Registry.instance

      # User plugins are those installed by the user via `dynamo plugin install`
      # and are installed under ~/.dynamo/gems
      unless options[:omit_user_plugins]
        @conf_file = Dynamo::Plugin::V2::ConfigFile.new
        read_conf_file_into_registry
      end

      # Old-style (v0, v1) co-distributed plugins were called 'bundles'
      # and were located in lib/bundles
      detect_bundled_plugins unless options[:omit_bundles]

      # New-style (v2) co-distributed plugins are in lib/plugins,
      # and may be safely loaded
      detect_core_plugins unless options[:omit_core_plugins]

      # Identify plugins that dynamo is co-installed with
      detect_system_plugins unless options[:omit_sys_plugins]
    end

    def load_all
      # This fixes the gem paths on some bundles
      Gem.path << plugin_gem_path
      Gem.refresh

      # Be careful not to actually iterate directly over the registry here;
      # we want to allow "sidecar loading", in which case a plugin may add an entry to the registry.
      registry.plugin_names.dup.each do |plugin_name|
        plugin_details = registry[plugin_name]

        # Under some conditions (kitchen-dynamo with multiple test suites, for example), this may be
        # called multple times. Don't reload anything.
        next if plugin_details.loaded

        # We want to capture literally any possible exception here, since we are storing them.
        # rubocop: disable Lint/RescueException
        begin
          # We could use require, but under testing, we need to repeatedly reload the same
          # plugin.  However, gems only work with require (rubygems dooes not overload `load`)
          case plugin_details.installation_type
          when :user_gem
            activate_managed_gems_for_plugin(plugin_name)
            require plugin_details.entry_point
          when :system_gem
            require plugin_details.entry_point
          else
            load_path = plugin_details.entry_point
            load_path += ".rb" unless plugin_details.entry_point.end_with?(".rb")
            load load_path
          end
          plugin_details.loaded = true
          annotate_status_after_loading(plugin_name)
        rescue ::Exception => ex
          plugin_details.load_exception = ex
          Dynamo::Log.error "Could not load plugin #{plugin_name}: #{ex.message}"
        end
        # rubocop: enable Lint/RescueException
      end
    end

    # This should possibly be in either lib/dynamo/cli.rb or Registry
    def exit_on_load_error
      if registry.any_load_failures?
        Dynamo::Log.error "Errors were encountered while loading plugins..."
        registry.plugin_statuses.select(&:load_exception).each do |plugin_status|
          Dynamo::Log.error "Plugin name: " + plugin_status.name.to_s
          Dynamo::Log.error "Error: " + plugin_status.load_exception.message
          if ARGV.include?("--debug")
            Dynamo::Log.error "Exception: " + plugin_status.load_exception.class.name
            Dynamo::Log.error "Trace: " + plugin_status.load_exception.backtrace.join("\n")
          end
        end
        Dynamo::Log.error("Run again with --debug for a stacktrace.") unless ARGV.include?("--debug")
        exit 2
      end
    end

    def activate_mentioned_cli_plugins(cli_args = ARGV)
      # Get a list of CLI plugin activation hooks
      registry.find_activators(plugin_type: :cli_command).each do |act|
        next if act.activated?

        # Decide whether to activate.  Several conditions, so split them out for clarity.
        # Assume no, to start.  Each condition may flip it true, which will short-circuit
        # all following ||= ops.
        activate_me = false

        # If the user invoked `dynamo help`, `dynamo --help`, or only `dynamo`
        # then activate all CLI plugins so they can display their usage message.
        activate_me ||= ["help", "--help", nil].include?(cli_args.first)

        # If there is anything in the CLI args with the same name, activate it.
        # This is the expected usual activation for individual plugins.
        # `dynamo dosomething` => activate the :dosomething hook
        activate_me ||= cli_args.include?(act.activator_name.to_s)

        # Only one compliance command to be activated at one time.
        # Since both commands are defined in the same class,
        # activators were not getting fetched uniquely.
        if cli_args.include?("automate") && act.activator_name.to_s.eql?("compliance")
          activate_me = false
        elsif cli_args.include?("compliance") && act.activator_name.to_s.eql?("automate")
          activate_me = false
        end

        # OK, activate.
        if activate_me
          act.activate
          act.implementation_class.register_with_thor
        end
      end
    end

    def plugin_gem_path
      self.class.plugin_gem_path
    end

    def self.plugin_gem_path
      require "rbconfig" unless defined?(RbConfig)
      ruby_abi_version = RbConfig::CONFIG["ruby_version"]
      # TODO: why are we installing under the api directory for plugins?
      base_dir = Dynamo.config_dir
      base_dir = File.realpath base_dir if File.exist? base_dir
      File.join(base_dir, "gems", ruby_abi_version)
    end

    # Lists all gems found in the plugin_gem_path.
    # @return [Array[Gem::Specification]] Specs of all gems found.
    def self.list_managed_gems
      Dir.glob(File.join(plugin_gem_path, "specifications", "*.gemspec")).map { |p| Gem::Specification.load(p) }
    end

    def list_managed_gems
      self.class.list_managed_gems
    end

    # Lists all plugin gems found in the plugin_gem_path.
    # This is simply all gems that begin with an accepted prefix
    # and are not on the exclusion list.
    # @return [Array[Gem::Specification]] Specs of all gems found.
    def self.list_installed_plugin_gems
      list_managed_gems.select { |spec| valid_plugin_name?(spec.name) }
    end

    def list_installed_plugin_gems
      self.class.list_managed_gems
    end

    private

    # 'Activating' a gem adds it to the load path, so 'require "gemname"' will work.
    # Given a gem name, this activates the gem and all of its dependencies, respecting
    # version pinning needs.
    def activate_managed_gems_for_plugin(plugin_gem_name, version_constraint = "> 0")
      # TODO: enforce first-level version pinning
      plugin_deps = [Gem::Dependency.new(plugin_gem_name.to_s, version_constraint)]
      managed_gem_set = Gem::Resolver::VendorSet.new
      list_managed_gems.each { |spec| managed_gem_set.add_vendor_gem(spec.name, spec.gem_dir) }

      # TODO: Next two lines merge our managed gems with the other gems available
      # in our "local universe" - which may be the system, or it could be in a Bundler microcosm,
      # or rbenv, etc. Do we want to merge that, though?
      distrib_gem_set = Gem::Resolver::CurrentSet.new
      installed_gem_set = Gem::Resolver.compose_sets(managed_gem_set, distrib_gem_set)

      # So, given what we need, and what we have available, what activations are needed?
      resolver = Gem::Resolver.new(plugin_deps, installed_gem_set)
      begin
        solution = resolver.resolve
      rescue Gem::UnsatisfiableDependencyError => gem_ex
        # If you broke your install, or downgraded to a plugin with a bad gemspec, you could get here.
        ex = Dynamo::Plugin::V2::LoadError.new(gem_ex.message)
        raise ex
      end
      solution.each do |activation_request|
        next if activation_request.full_spec.activated?

        activation_request.full_spec.activate
        # TODO: If we are under Bundler, inform it that we loaded a gem
      end
    end

    def annotate_status_after_loading(plugin_name)
      status = registry[plugin_name]
      return if status.api_generation == 2 # Gen2 have self-annotating superclasses

      case status.installation_type
      when :bundle
        annotate_bundle_plugin_status_after_load(plugin_name)
      else
        # TODO: are there any other cases? can this whole thing be eliminated?
        raise "I only know how to annotate :bundle plugins when trying to load plugin #{plugin_name}" unless status.installation_type == :bundle
      end
    end

    def annotate_bundle_plugin_status_after_load(plugin_name)
      # HACK: we're relying on the fact that all bundles are gen0 and cli type
      status = registry[plugin_name]
      status.api_generation = 0
      act = Activator.new
      act.activated = true
      act.plugin_type = :cli_command
      act.plugin_name = plugin_name
      act.activator_name = :default
      status.activators = [act]

      v0_subcommand_name = plugin_name.to_s.gsub("#{PREFIX}-", "")
      status.plugin_class = Dynamo::Plugins::CLI.subcommands[v0_subcommand_name][:klass]
    end

    def detect_bundled_plugins
      bundle_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "bundles"))
      globs = [
        File.join(bundle_dir, "${PREFIX}-*.rb"),
      ]
      Dir.glob(globs).each do |loader_file|
        name = File.basename(loader_file, ".rb").to_sym
        status = Dynamo::Plugin::V2::Status.new
        status.name = name
        status.entry_point = loader_file
        status.installation_type = :bundle
        status.loaded = false
        registry[name] = status
      end
    end

    def detect_core_plugins
      core_plugins_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "plugins"))
      # These are expected to be organized as proper separate projects,
      # with lib/ dirs, etc.
      Dir.glob(File.join(core_plugins_dir, "#{PREFIX}-*")).each do |plugin_dir|
        status = Dynamo::Plugin::V2::Status.new
        status.name = File.basename(plugin_dir).to_sym
        status.entry_point = File.join(plugin_dir, "lib", status.name.to_s + ".rb")
        status.installation_type = :core
        status.loaded = false
        registry[status.name.to_sym] = status
      end
    end

    def read_conf_file_into_registry
      conf_file.each do |plugin_entry|
        status = Dynamo::Plugin::V2::Status.new
        status.name = plugin_entry[:name]
        status.loaded = false
        status.installation_type = (plugin_entry[:installation_type] || :user_gem)
        case status.installation_type
        when :user_gem
          status.entry_point = status.name.to_s
          status.version = plugin_entry[:version]
        when :path
          status.entry_point = plugin_entry[:installation_path]
        end

        registry[status.name] = status
      end
    end

    def find_dynamo_gemspec(name, ver)
      Gem::Specification.find_by_name(name, ver)
    rescue Gem::MissingSpecError
      nil
    end

    def detect_system_plugins
      # Find the gemspec for dynamo
      dynamo_gemspec =
        find_dynamo_gemspec("dynamo",      "=#{Dynamo::VERSION}") ||
        find_dynamo_gemspec("dynamo-core", "=#{Dynamo::VERSION}")

      unless dynamo_gemspec
        Dynamo::Log.warn "dynamo gem not found, skipping detecting of system plugins"
        return
      end

      # Make a RequestSet that represents the dependencies of dynamo
      dynamo_deps_request_set = Gem::RequestSet.new(*dynamo_gemspec.dependencies)
      dynamo_deps_request_set.remote = false

      # Resolve the request against the installed gem universe
      gem_resolver = Gem::Resolver::CurrentSet.new
      runtime_solution = dynamo_deps_request_set.resolve(gem_resolver)

      dynamo_gemspec.dependencies.each do |dynamo_dep|
        next unless dynamo_plugin_name?(dynamo_dep.name)

        plugin_spec = runtime_solution.detect { |s| s.name == dynamo_dep.name }.spec

        status = Dynamo::Plugin::V2::Status.new
        status.name = dynamo_dep.name
        status.entry_point = dynamo_dep.name # gem-based, just 'require' the name
        status.version = plugin_spec.version.to_s
        status.loaded = false
        status.installation_type = :system_gem
        status.api_generation = 2

        registry[status.name.to_sym] = status
      end
    end
  end
end
