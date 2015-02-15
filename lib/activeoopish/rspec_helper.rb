require 'rspec/core'
require 'rspec/matchers'
require 'active_model'
require 'active_support'

RSpec::Matchers.define :be_monitored_by do |validator_class|
  match do |actual|
    validator_class.respond_to?(:monitoring?) && validator_class.monitoring?(actual)
  end
end

module ActiveOOPish
  module RSpecHelper
    module SharedContext
      extend ActiveSupport::Concern

      included do
        let(:model_class) do
          Class.new(ActiveOOPish::RSpecHelper::ValidationTarget) do
            def self.name
              'ValidationTarget'
            end
          end
        end

        shared_context 'describe declaration', :describe_declaration do
          subject do
            described_class.monitor(model_class)
            model_class.new
          end
        end
      end
    end

    class ValidationTarget
      include ActiveModel::Validations

      def initialize(attributes = {})
        @attributes = attributes
      end

      def read_attribute_for_validation(key)
        @attributes[key.to_sym]
      end

      private

      def remove_trailing_equal(string)
        string[0...-1].to_sym
      end

      def method_missing(name, *args)
        if name.to_s.end_with?('=')
          name = remove_trailing_equal(name)
          @attributes[name] = args.first
        elsif @attributes.include?(name)
          read_attribute_for_validation(name)
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include ActiveOOPish::RSpecHelper::SharedContext, :with_activeoopish_helpers
end
