require 'activeoopish/rspec_helper'

describe 'activeoopish matchers' do
  describe 'be_monitored_by matcher' do
    let(:model_class) do
      Struct.new(:attr) do
        include ActiveModel::Validations

        def self.name
          'ModelClass'
        end
      end
    end

    let(:validator_class) do
      Class.new(ActiveOOPish::Validator) do
        declear do
        end

        def self.name
          'Sample::Validator'
        end
      end
    end

    shared_examples_for 'be_monitored_by' do
      context 'and the model_class is not monitored by the validator_class' do
        it { should_not be_monitored_by validator_class }
      end

      context 'and the model_class is monitored by the validator_class' do
        before do
          validator_class.monitor(model_class)
        end

        it { should be_monitored_by validator_class }
      end
    end

    context 'when the subject is the model_class' do
      subject do
        model_class
      end

      include_examples 'be_monitored_by'
    end

    context 'when the subject is the instance of the model_class' do
      subject do
        model_class.new
      end

      include_examples 'be_monitored_by'
    end
  end
end
