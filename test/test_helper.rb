# frozen_string_literal: true

require 'fabrial'
require 'bundler/setup'
require 'pry'
Bundler.require

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'minitest/autorun'
require 'minitest/reporters'
require 'minitest/focus'
require 'database_cleaner'
require 'mocha/setup'

if ENV['CONTINUOUS_INTEGRATION']
  Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new(color: true)
else
  Minitest::Reporters.use! Minitest::Reporters::ProgressReporter.new
end

ActiveSupport::TestCase.extend(Minitest::Spec::DSL)
ActiveSupport::TestCase.test_order = :alpha

DatabaseCleaner.strategy = :transaction
class ActiveSupport::TestCase
  before do
    DatabaseCleaner.start
  end

  after do
    DatabaseCleaner.clean
  end
end
