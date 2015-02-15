require 'coveralls'
Coveralls.wear!

require 'active_model'
require 'shoulda-matchers'

require 'activeoopish'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
end
