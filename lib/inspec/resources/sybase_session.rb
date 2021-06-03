require "inspec/resources/command"
require "inspec/utils/database_helpers"
require "hashie/mash"
require "csv" unless defined?(CSV)

module Inspec::Resources
  # STABILITY: Experimental
  # This resource needs further testing and refinement
  #
  class SybaseSession < Inspec.resource(1)
    name "sybase_session"
    supports platform: "unix"
    # supports platform: "windows" # TODO
    desc "Use the sybasedb_session InSpec resource to test commands against an Sybase database"
    example <<~EXAMPLE
      sql = sybasedb_session(username: 'my_user', password: 'password', server: 'SYBASE', database: 'pubs2')
      describe sql.query(\"SELECT * FROM authors\").row(0).column('au_lname') do
        its('value') { should eq 'Smith' }
      end
    EXAMPLE

    # TODO: allow to set -I interfaces file
    # TODO: allow to customize -s column separator
    attr_reader :bin, :col_sep, :database, :password, :server, :sybase_home, :username

    def initialize(opts = {})
      @username = opts[:username]
      @password = opts[:password]
      @database = opts[:database]
      @server = opts[:server]
      @sybase_home = opts[:sybase_home] || "/opt/sap"
      @bin = opts[:bin] || "isql"
      @col_sep = "|"

      fail_resource "Can't run Sybase checks without authentication" unless username && password
      fail_resource "You must provide a server name for the session" unless server
      fail_resource "You must provide a database name for the session" unless database
      fail_resource "Cannot find #{bin} CLI tool" unless inspec.command(bin).exist?
    end

    def query(sql)
      # We must write the SQl to a temp file on the remote target
      # try to get a temp path
      sql_file_path = "/tmp/sybase_tmp_sql" # TODO: use tempfile utility if available

      # TODO: replace echos with a a train upload command if possible.
      # echos are senstive to shell interpolation, such as the asterisk in SELECT *
      inspec.command("echo #{sql} > #{sql_file_path}").exit_status # TODO: handle
      inspec.command("echo go >> #{sql_file_path}").exit_status # TODO: handle

      # isql reuires that we have a matching locale set, but does not support C.UTF-8. en_US.UTF-8 is the least evil.
      command = "LANG=en_US.UTF-8 SYBASE=#{sybase_home} #{bin} -s\"#{col_sep}\" -w80000 -S #{server} -U #{username} -D #{database} -P \"#{password}\" < #{sql_file_path}"
      isql_cmd = inspec.command(command)

      # Check for isql errors
      res = isql_cmd.exit_status
      raise Inspec::Exceptions::ResourceFailed.new("isql exited with code #{res} and stderr '#{isql_cmd.stderr}', stdout '#{isql_cmd.stdout}'") unless res == 0
      # isql is ill-behaved, and returns 0 on error
      raise Inspec::Exceptions::ResourceFailed.new("isql exited with error '#{isql_cmd.stderr}', stdout '#{isql_cmd.stdout}'") unless isql_cmd.stderr == ""
      # check stdout for error messages when stderr is empty "Msg 102, Level 15, State 181:\nServer 'SYBASE', Line 1:\nIncorrect syntax near '.'.\n"
      raise Inspec::Exceptions::ResourceFailed.new("isql exited with error #{isql_cmd.stdout}") if isql_cmd.stdout.match?(/Msg\s\d+,\sLevel\s\d+,\sState\s\d+/)

      # Clean up temporary file
      rm_cmd = inspec.command("rm #{sql_file_path}")
      res = rm_cmd.exit_status # TODO: handle
      raise Inspec::Exceptions::ResourceFailed.new("Unable to delete temproary SQL input file at #{sql_file_path}: #{rm_cmd.stderr}") unless res == 0

      DatabaseHelper::SQLQueryResult.new(isql_cmd, parse_csv_result(isql_cmd.stdout))
    end

    def to_s
      "Sybase Session"
    end

    private

    def parse_csv_result(stdout)
      output = stdout.sub(/\r/, "").strip
      lines = output.lines
      # Remove second row (all dashes) and last two rows (blank and summary line)
      trimmed_output = ([lines[0]] << lines.slice(2..-3)).join("\n")
      header_converter = ->(header) { header.downcase.strip }
      field_converter = ->(field) { field&.strip }
      CSV.parse(trimmed_output, headers: true, header_converters: header_converter, converters: field_converter, col_sep: col_sep).map { |row| Hashie::Mash.new(row.to_h) }
    end
  end
end