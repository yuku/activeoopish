require 'rspec/core'
require 'rspec/matchers'

RSpec::Matchers.define :be_monitored_by do |validator_class|
  match do |actual|
    validator_class.respond_to?(:monitoring?) && validator_class.monitoring?(actual)
  end
end
