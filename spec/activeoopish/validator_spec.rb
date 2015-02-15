describe ActiveOOPish::Validator do
  describe '.monitor' do
    subject do
      validator_class.monitor(model_class)
    end

    let(:model_class) do
      Struct.new(:attr) do
        include ActiveModel::Validations

        def self.name
          'ModelClass'
        end
      end
    end

    context 'when the validator_class does not have declaration' do
      let(:validator_class) do
        Class.new(described_class) do
          def self.name
            'Sample::Validator'
          end
        end
      end

      it { expect { subject }.to raise_error(described_class::DeclarationNotFound) }
    end

    context 'when the validator_class has declaration' do
      let(:validator_class) do
        Class.new(described_class) do
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

          def self.name
            'Sample::Validator'
          end
        end
      end

      it 'apply decleared validations to the given model_class' do
        instance = model_class.new
        expect(instance).not_to validate_exclusion_of(:attr).in_array(%w(a b c))
        expect(instance).not_to validate_inclusion_of(:attr).in_array(%w(x y z))
        expect(instance).not_to validate_length_of(:attr).is_at_least(1).is_at_most(10)
        expect(instance).not_to validate_numericality_of(:attr).only_integer
        expect(instance).not_to validate_presence_of(:attr)

        subject

        instance = model_class.new
        expect(instance).to validate_exclusion_of(:attr).in_array(%w(a b c))
        # expect(instance).to validate_inclusion_of(:attr).in_array(%w(x y z))
        expect(instance).to validate_length_of(:attr).is_at_least(1).is_at_most(10)
        expect(instance).to validate_numericality_of(:attr).only_integer
        expect(instance).to validate_presence_of(:attr)
      end

      context 'and it declears `validate` with if and unless options' do
        let(:validator_class) do
          Class.new(described_class) do
            declear do
              validate :validate_method, if: :if_cond?, unless: :unless_cond?
            end

            def self.name
              'Sample::Validator'
            end

            private

            def if_cond?(_)
              true
            end

            def unless_cond?(_)
              false
            end

            def validate_method(_)
            end
          end
        end

        it 'makes corresponding methods be called with the instance when validating it' do
          subject  # Start monitoring
          instance = model_class.new

          expect_any_instance_of(validator_class)
            .to receive(:if_cond?).with(instance).once.and_call_original
          expect_any_instance_of(validator_class)
            .to receive(:unless_cond?).with(instance).once.and_call_original
          expect_any_instance_of(validator_class)
            .to receive(:validate_method).with(instance).once

          instance.valid?  # Validate the instance
        end

        context 'and if condition returns false' do
          before do
            allow_any_instance_of(validator_class).to receive(:if_cond?).and_return(false)
          end

          it 'skips the corresponding validate method' do
            subject  # Start monitoring
            instance = model_class.new

            expect_any_instance_of(validator_class).not_to receive(:validate_method)
            instance.valid?
          end
        end

        context 'and unless condition returns true' do
          before do
            allow_any_instance_of(validator_class).to receive(:unless_cond?).and_return(true)
          end

          it 'skips the corresponding validate method' do
            subject  # Start monitoring
            instance = model_class.new

            expect_any_instance_of(validator_class).not_to receive(:validate_method)
            instance.valid?
          end
        end
      end

      context 'and the model_class has already been monitored' do
        before do
          validator_class.monitor(model_class)
        end

        it { expect { subject }.to raise_error(described_class::AlreadyMonitored) }
      end
    end
  end

  describe '.monitoring?' do
    subject do
      validator_class.monitoring?(param)
    end

    let(:validator_class) do
      Class.new(described_class) do
        declear do
        end

        def self.name
          'Sample::Validator'
        end
      end
    end

    let(:model_class) do
      Class.new do
        include ActiveModel::Validations

        def self.name
          'ModelClass'
        end
      end
    end

    shared_examples_for '.monitoring?' do
      context 'and it does not monitor the model_class' do
        it { should be_falsey }
      end

      context 'and it monitors the model_class' do
        before do
          validator_class.monitor(model_class)
        end

        it { should be_truthy }
      end
    end

    context 'when the given parameter is model_class' do
      let(:param) do
        model_class
      end

      include_examples '.monitoring?'
    end

    context 'when the given parameter is the instance of model_class' do
      let(:param) do
        model_class.new
      end

      include_examples '.monitoring?'
    end
  end

  describe '.injection_name' do
    subject do
      validator_class.injection_name
    end

    let(:validator_class) do
      Class.new(described_class) do
        declear do
        end

        def self.name
          'Sample::Validator'
        end
      end
    end

    it { should be_a String }
  end
end
