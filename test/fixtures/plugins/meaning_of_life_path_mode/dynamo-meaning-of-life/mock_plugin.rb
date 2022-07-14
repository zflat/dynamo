module DynamoPlugins
  module MeaningOfLife
    class MockPlugin < Dynamo.plugin(2, :mock_plugin_type)

      # Do mockish things
      def execute(opts)
        42
      end
    end

  end
end
