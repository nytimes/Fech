require 'rubygems'
require 'bundler/setup'

require 'rspec'
require 'fech'

RSpec.configure do |config|
  config.mock_framework = :mocha
end
