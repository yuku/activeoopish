require 'active_support/core_ext/module/delegation'

module ActiveOopish
  # Public: Base class for validators.
  #
  # Example
  #
  #   class BookValidator < ActiveOopish::Validator
  #     declear do
  #       validates :author, presence: true
  #       validate :title_must_include_author_name, if: :biography?
  #     end
  #
  #     private
  #
  #     def title_must_include_author_name(book)
  #       unless book.title.include?(book.author.name)
  #         book.errors.add(:author, "cannot write a biography for other people")
  #       end
  #     end
  #
  #     def biography?(book)
  #       book.category == :biography
  #     end
  #   end
  #
  #   class Book < ActiveRecord::Base
  #     belongs_to :author, class_name: 'User'
  #     BookValidator.monitor(self)
  #   end
  #
  #   BookValidator.monitor?(Book)
  #   # => true
  #
  #   book = Book.new(title: 'Qiitan biography', author: User.new(name: 'Yaotti'))
  #
  #   book.valid?
  #   # => false
  #
  #   book.errors.full_messages_for(:author).first
  #   # => "author cannot write a biography of another person"
  #
  class Validator
    # Public: Generic ActiveOopish::Validator related error.
    # Exceptions raised in this class should inherit from Error.
    class Error < StandardError
    end

    # Public: Raised when
    class AlreadyMonitored < Error
    end

    # Public: Raised when a non-decleared validator tries to validate a model.
    class DeclarationNotFound < Error
    end

    class << self
      # Public: Start validating the given model_class's instances.
      #
      # model_class - A model Class to be validated by it.
      #
      # Raises AlreadyMonitored if the given model_class has already been
      #   monitored.
      # Raises DeclarationNotFound when it has not decleared yet.
      # Returns nothing.
      def monitor(model_class)
        fail AlreadyMonitored if monitoring?(model_class)
        define_accessor_to_model_class(model_class)
        apply_decleared_rules_to_model_class(model_class)
        monitoring_model_classes << model_class
      end

      # Public: Whether the given model_class is watched by it.
      #
      # target - A class which includes ActiveModel::Validations or its instance.
      #
      # Returns true or false.
      def monitoring?(target)
        model_class = target.is_a?(ActiveModel::Validations) ? target.class : target
        monitoring_model_classes.include?(model_class)
      end

      # Internal: Its name.
      #
      # Returns a Symbol.
      def injection_name
        @method_name ||= "__validator_#{name.downcase.gsub('::', '_')}"
      end

      def inspect
        name
      end

      private

      def monitoring_model_classes
        @monitoring_model_classes ||= []
      end

      # Internal: Declear how to validate a model class.
      #
      # block - A block which will be applied later.
      #         It may call `validates`, `validates_with` and `validate`
      #         methods to self of the block context.
      #
      # Example
      #
      #   Validator.declear do
      #     # Delegated to @model_class.
      #     validates :name, presence: true
      #     validates_with AnActiveModelValidator
      #
      #     # Create a proxy method to the corresponding validator method.
      #     validate :validate_method
      #   end
      #
      # Returns nothing.
      def declear(&block)
        @declaration = block
      end

      # Internal: Define a private instance method something like
      #
      #   def __validator_bookvalidator
      #     @__validator_bookvalidator ||= BookValidator.new
      #   end
      #
      # to the given model_class.
      #
      # model_class - A model Class to be validated by it.
      #
      # Returns nothing.
      def define_accessor_to_model_class(model_class)
        validator_class = self

        model_class.class_eval do
          unless private_instance_methods(false).include?(validator_class.injection_name)
            define_method(validator_class.injection_name) do
              instance_variable_set("@#{validator_class.injection_name}", validator_class.new)
            end
            private validator_class.injection_name
          end
        end
      end

      def apply_decleared_rules_to_model_class(model_class)
        fail DeclarationNotFound unless @declaration
        @model_class = model_class
        begin
          class_eval(&@declaration)
        ensure
          @model_class = nil
        end
      end

      # TODO: Support `validate` in `with_options` block.
      delegate(
        :validates, :validates_with, :validates_associated, :with_options,
        to: :@model_class
      )

      # Internal: Define a private method to the model class which works as a
      # proxy for the validator's corresponding method. The validator method
      # will be called with the model instance as the first argument.
      #
      # Suppose a `UserValidator` declears:
      #
      #   validate :must_be_qiitan, if: :active?
      #
      # then, this method defines some private methods to the @model_class
      # something like:
      #
      #   def __validator_uservalidator_validate_must_be_qiitan
      #     __validator_uservalidator.__send__(:must_be_qiitan, self)
      #   end
      #
      #   def __validator_uservalidator_if_active?
      #     __validator_uservalidator.__send__(:active?, self)
      #   end
      #
      #   validate(
      #     :__validator_uservalidator_validate_must_be_qiitan,
      #     if: __validator_user_validator_if_active?
      #   )
      #
      # Note that it does not support a block and a proc for :if and :unless
      # options, though ActiveModel::Validations::ClassMethods.validate
      # supports them.
      #
      # Returns nothing.
      def validate(method_name, options = {})
        validator_class = self

        proxy_method_name = "#{validator_class.injection_name}_validate_#{method_name}"
        proxy_map = { proxy_method_name => method_name }

        (options.keys & [:if, :unless]).each do |key|
          value = options[key]
          proxy_name = "#{validator_class.injection_name}_#{key}_#{value}"
          proxy_map[proxy_name] = value
          options[key] = proxy_name
        end

        @model_class.class_eval do
          proxy_map.each_pair do |model_method_name, validator_method_name|
            unless private_instance_methods(false).include?(model_method_name)
              define_method(model_method_name) do
                __send__(validator_class.injection_name).__send__(validator_method_name, self)
              end
              private model_method_name
            end
          end

          # Add the proxy method to the model_class as a validation method.
          validate(proxy_method_name, **options)
        end
      end
    end
  end
end
