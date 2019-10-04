# frozen_string_literal: true

require 'fabrial'
require 'bundler/setup'
Bundler.require

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'minitest/autorun'
require 'minitest/reporters'
require 'minitest/focus'

if ENV['CONTINUOUS_INTEGRATION']
  Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new(color: true)
else
  Minitest::Reporters.use! Minitest::Reporters::ProgressReporter.new
end

ActiveSupport::TestCase.extend(Minitest::Spec::DSL)
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
