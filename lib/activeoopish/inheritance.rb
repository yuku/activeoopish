require 'active_support/concern'

module ActiveOopish
  module Inheritance
    extend ActiveSupport::Concern

    included do
      instance_variable_set('@instantiation_rules', [])
    end

    module ClassMethods
      # Public:
      #
      # class_name - A String represents the class which instantiates an instance.
      # condition  - A Hash.
      #
      def instantiate_as(class_name, options = {})
        @instantiation_rules ||= []
        @instantiation_rules << { class_name: class_name, condition: options.stringify_keys }
      end

      private

      # Internal: Called by ActiveRecord::Persistence.instantiate to decide which
      # class to use for a new record instance.
      #
      # Returns a Class to instantiate an instance.
      def discriminate_class_for_record(record)
        @instantiation_rules ||= []
        @instantiation_rules.each do |rule|
          satisfy_rule = rule[:condition].each_pair.all? do |column, expected|
            record[column] == expected
          end
          return rule[:class_name].constantize if satisfy_rule
        end
        self
      end
    end
  end
end
