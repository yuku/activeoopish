require 'activeoopish/rspec_helper'

describe 'activeoopish matchers' do
  describe 'be_monitored_by matcher', :with_activeoopish_helpers do
    let(:validator_class) do
      Class.new(ActiveOopish::Validator) do
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

class SampleValidator < ActiveOopish::Validator
  declear do
    validates(
      :attr,
      exclusion: { in: %w(a b c) },
      inclusion: { in: %w(x y z) },
      length: { minimum: 1, maximum: 10 },
      numericality: { only_integer: true },
      presence: true
    )
  end
end

describe SampleValidator, :with_activeoopish_helpers do
  include_context 'describe declaration' do
    it { should validate_exclusion_of(:attr).in_array(%w(a b c)) }
    # it { should validate_inclusion_of(:attr).in_array(%w(x y z)) }
    it { should validate_length_of(:attr).is_at_least(1).is_at_most(10) }
    it { should validate_numericality_of(:attr).only_integer }
    it { should validate_presence_of(:attr) }
  end
end
