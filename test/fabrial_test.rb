# frozen_string_literal: true

require 'test_helper'

class FabrialTest < ActiveSupport::TestCase
  describe 'ensure that the test suite is configured correctly' do
    test 'truth' do
      assert true
    end

    test 'version' do
      refute_nil ::Fabrial::VERSION
    end
  end
end
