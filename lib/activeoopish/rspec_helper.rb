require 'rspec/core'
require 'rspec/matchers'
require 'active_model'

RSpec::Matchers.define :be_monitored_by do |validator_class|
  match do |actual|
    validator_class.respond_to?(:monitoring?) && validator_class.monitoring?(actual)
  end
end

module ActiveOOPish
  module RSpecHelper
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
        else
          super
        end
      end
    end
  end
end
