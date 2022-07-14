module InspecPlugins
  module MeaningOfLife

    class Plugin < Inspec.plugin(2)
      plugin_name :'dynamo-meaning-of-life'

      mock_plugin_type :'meaning-of-life-the-universe-and-everything' do
        # NOTE: we can't use require, because these test files are repeatedly reloaded
        load "test/fixtures/plugins/meaning_of_life_path_mode/dynamo-meaning-of-life/mock_plugin.rb"
        InspecPlugins::MeaningOfLife::MockPlugin
      end

      cli_command :meaningoflife do
        # NOTE: we can't use require, because these test files are repeatedly reloaded
        load "test/fixtures/plugins/meaning_of_life_path_mode/dynamo-meaning-of-life/cli_command.rb"
        InspecPlugins::MeaningOfLife::CliCommand
      end
    end

  end
end
