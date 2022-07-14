module DynamoPlugins::TestUI
  class CliCommand < Dynamo.plugin(2, :cli_command)
    subcommand_desc "testui [FEATURE] [OPTS]", "Exercise Dynamo::UI"

    #--------------------------------------------------#
    #                   UI Output Commands
    #--------------------------------------------------#
    desc "headline", "Dynamo::UI#headline"
    def headline
      ui.headline("Big News!")
    end

    desc "table", "Dynamo::UI#table"
    def table
      ui.table do |t|
        t.header = ["Band", "Coolness", "Nerd Cred"]
        t << ["They Might Be Giants", "Low", "Very High"]
        t << ["Led Zep", "High", "Low"]
        t << ["Talking Heads", "Moderate", "High"]
      end
    end

    desc "warning", "Dynamo::UI#warning"
    def warning
      ui.warning("Things will be OK in the end")
    end

    desc "error", "Dynamo::UI#error"
    def error
      ui.error("Burned down, fell over, and then sank into the swamp.")
    end

    desc "list_item", "Dynamo::UI#list_item"
    def list_item
      ui.list_item("TODO: make more lists")
    end

    desc "everything", "Demo all UI features"
    def everything
      headline
      table
      warning
      error
      list_item
    end

    #--------------------------------------------------#
    #               Interactivity
    #--------------------------------------------------#
    desc "prompt", "Tries to prompt the user"
    def prompt
      ui.prompt.keypress("Apollo 18, ready to launch! :countdown", timeout: 1)
    end

    desc "interactive", "Dynamo::UI#interactive?"
    def interactive
      ui.plain_line(ui.interactive?.to_s)
    end

    #--------------------------------------------------#
    #           Exit code Testing Commands
    #--------------------------------------------------#
    %i{
      normal
      usage_error
      plugin_error
      skipped_tests
      failed_tests
      tea
    }.each do |exit_mode|
      short = "exit" + exit_mode.to_s.split("_").first
      desc short, "Exit with code for #{exit_mode}"
      define_method short.to_sym do
        ui.plain("test exit #{exit_mode}\n")
        ui.exit(exit_mode)
      end
    end
  end
end
