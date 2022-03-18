require "thor" # rubocop:disable Chef/Ruby/UnlessDefinedRequire
require "inspec/log"
require "inspec/ui"
require "inspec/config"
require "inspec/dist"
require "inspec/utils/deprecation/global_method"

# Allow end of options during array type parsing
# https://github.com/erikhuda/thor/issues/631
class Thor::Arguments
  alias old_parse_array parse_array

  def parse_array(_name)
    return shift if peek.is_a?(Array)

    array = []
    while current_is_value?
      break unless @parsing_options

      array << shift
    end
    array
  end
end

module Inspec
  class BaseCLI < Thor
    class << self
      attr_accessor :inspec_cli_command
    end

    def self.start(given_args = ARGV, config = {})
      super(given_args, config)
    end

    # https://github.com/erikhuda/thor/issues/244
    def self.exit_on_failure?
      true
    end

    def self.help(*args)
      super(*args)
      puts "\n#{Inspec::Dist::PRODUCT_NAME}: runs Thor generators"
    end

    def self.format_platform_info(params: {}, indent: 0, color: 39, enable_color: true)
      str = ""
      params.each do |item, info|
        data = info

        # Format Array for better output if applicable
        data = data.join(", ") if data.is_a?(Array)

        # Do not output fields of data is missing ('unknown' is fine)
        next if data.nil?

        data = "\e[1m\e[#{color}m#{data}\e[0m" if enable_color
        str << format("#{" " * indent}%-10s %s\n", item.to_s.capitalize + ":", data)
      end
      str
    end

    # These need to be public methods on any BaseCLI instance,
    # but Thor interprets all methods as subcommands.  The no_commands block
    # treats them as regular methods.
    no_commands do
      def ui
        return @ui if defined?(@ui)

        # Make a new UI object, respecting context
        if options[:color].nil?
          enable_color = true # If the command does not support the color option, default to on
        else
          enable_color = options[:color]
        end

        # UI will probe for TTY if nil - just send the raw option value
        enable_interactivity = options[:interactive]

        @ui = Inspec::UI.new(color: enable_color, interactive: enable_interactivity)
      end

      # Rationale: converting this to attr_writer breaks Thor
      def ui=(new_ui) # rubocop: disable Style/TrivialAccessors
        @ui = new_ui
      end

      def mark_text(text)
        Inspec.deprecate(:inspec_ui_methods)
        # Note that this one doesn't automatically print
        ui.emphasis(text, print: false)
      end

      def headline(title)
        Inspec.deprecate(:inspec_ui_methods)
        ui.headline(title)
      end

      def li(entry)
        Inspec.deprecate(:inspec_ui_methods)
        ui.list_item(entry)
      end

      def plain_text(msg)
        Inspec.deprecate(:inspec_ui_methods)
        ui.plain(msg + "\n")
      end

      def exit(code)
        Inspec.deprecate(:inspec_ui_methods)
        ui.exit code
      end
    end

    private

    ALL_OF_OUR_REPORTERS = %w{json json-min json-rspec json-automate junit html html2 yaml documentation progress}.freeze # BUT WHY?!?!

    def suppress_log_output?(opts)
      return false if opts["reporter"].nil?

      match = ALL_OF_OUR_REPORTERS & opts["reporter"].keys

      unless match.empty?
        match.each do |m|
          # check to see if we are outputting to stdout
          return true if opts["reporter"][m]["stdout"] == true
        end
      end

      false
    end

    def diagnose(_ = nil)
      config.diagnose
    end

    def config
      @config ||= Inspec::Config.new(options) # 'options' here is CLI opts from Thor
    end

    # get the log level
    # DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
    def get_log_level(level)
      valid = %w{debug info warn error fatal}

      if valid.include?(level)
        l = level
      else
        l = "info"
      end

      Logger.const_get(l.upcase)
    end

    def pretty_handle_exception(exception)
      case exception
      when Inspec::Error
        $stderr.puts exception.message
        exit(1)
      else
        raise exception
      end
    end

    def vendor_deps(path, opts)
      require "inspec/profile_vendor"

      profile_path = path || Dir.pwd
      profile_vendor = Inspec::ProfileVendor.new(profile_path)

      if (profile_vendor.cache_path.exist? || profile_vendor.lockfile.exist?) && !opts[:overwrite]
        puts "Profile is already vendored. Use --overwrite."
        return false
      end

      profile_vendor.vendor!(opts)
      puts "Dependencies for profile #{profile_path} successfully vendored to #{profile_vendor.cache_path}"
    rescue StandardError => e
      pretty_handle_exception(e)
    end

    def configure_logger(o)
      #
      # TODO(ssd): This is a bit gross, but this configures the
      # logging singleton Inspec::Log. Eventually it would be nice to
      # move internal debug logging to use this logging singleton.
      #
      loc = if o["log_location"]
              o["log_location"]
            elsif suppress_log_output?(o)
              $stderr
            else
              $stdout
            end

      Inspec::Log.init(loc)
      Inspec::Log.level = get_log_level(o["log_level"])

      o[:logger] = Logger.new(loc)
      # output json if we have activated the json formatter
      if o["log-format"] == "json"
        o[:logger].formatter = Logger::JSONFormatter.new
      end
      o[:logger].level = get_log_level(o["log_level"])
    end
  end
end
