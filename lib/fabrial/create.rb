# frozen_string_literal: true

module Create
  attr_accessor :defaults

  class CallHash < Hash
    def [](key)
      value = super
      value.respond_to?(:call) ? value.call : value
    end

    def fetch(key)
      value = super
      value.respond_to?(:call) ? value.call : value
    end
  end

  def create(klass, data = {})
    # Find the base class of any STI types
    base = klass.base_class

    default_data = CallHash.new.merge(defaults[klass])
    default_data = default_data.merge(defaults[base])
    default_data = default_data.merge(data)

    klass.create! default_data
  end

  def serial_number(start=1, step=1)
    serializer = Enumerator.new do |yielder|
      loop do
        yielder << start
        start += step
      end
    end

    -> { serializer.next }
  end
  alias :sn :serial_number

  def serial_alpha(start='a')
    lambda do
      temp = start
      start = start.succ
      temp
    end
  end
  alias :sa :serial_alpha
end
