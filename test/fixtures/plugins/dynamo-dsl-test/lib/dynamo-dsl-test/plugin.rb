require "inspec/plugin/v2"

module DynamoPlugins
  module DslTest

    class Plugin < Dynamo.plugin(2)
      plugin_name :'inspec-dsl-test'

      outer_profile_dsl :favorite_grain do
        require_relative "outer_profile_dsl"
        DynamoPlugins::DslTest::OuterProfileDslFavoriteGrain
      end

      control_dsl :favorite_fruit do
        require_relative "control_dsl"
        DynamoPlugins::DslTest::ControlDslFavoriteFruit
      end

      describe_dsl :favorite_vegetable do
        require_relative "describe_dsl"
        DynamoPlugins::DslTest::DescribeDslFavoriteVegetable
      end

      test_dsl :favorite_legume do
        require_relative "test_dsl"
        DynamoPlugins::DslTest::TestDslFavoriteLegume
      end

      resource_dsl :food_type do
        require_relative "resource_dsl"
        DynamoPlugins::DslTest::ResourceDslFoodType
      end
    end
  end
end
