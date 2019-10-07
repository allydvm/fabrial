# frozen_string_literal: true

module Fabrial
  class Error < RuntimeError; end
  class UnknownClassError < Error; end
  class CreationError < Error
    def message
      return super unless cause

      "#{super}: #{cause.message}"
    end
  end
end
