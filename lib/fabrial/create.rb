# frozen_string_literal: true

module Create
  attr_accessor :defaults

  def create(klass, data = {})
    # Find the base class of any STI types
    base = klass.base_class

    default_data = defaults[klass]
    default_data ||= defaults[base]
    default_data ||= {}

    data = default_data.merge data
    klass.create! data
  end

  module AutoIds
    extend self

    @ids = {}

    # Get the next auto-incrementing id for the given klass
    def next(klass)
      id = @ids[klass] || 1
      @ids[klass] += 1
      id
    end
  end
end
