# frozen_string_literal: true

require 'fabrial/version'
require 'fabrial/errors'
require 'fabrial/fabricate'
require 'fabrial/create'

module Fabrial
  extend Fabricate
  extend Create
  self.defaults = {}

  @before_fabricate = nil
  def self.before_fabricate(&block)
    @before_fabricate = block
  end

  def self.run_before_fabricate(objects)
    if @before_fabricate
      @before_fabricate&.call objects
    else
      objects
    end
  end

  @before_create = nil
  def self.before_create(&block)
    @before_create = block
  end

  def self.run_before_create(klass, data, ancesstors, children)
    @before_create&.call klass, data, ancesstors, children
  end

  def self.reset
    @before_fabricate = nil
    @before_create = nil
  end
end
