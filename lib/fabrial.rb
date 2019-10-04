# frozen_string_literal: true

require 'fabrial/version'
require 'fabrial/fabricate'
require 'fabrial/create'

module Fabrial
  extend Fabricate
  extend Create
  self.defaults = {}
end
