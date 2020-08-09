# frozen_string_literal: true

require 'forwardable'
require 'parslet'
require 'llvm/core'
require 'llvm/execution_engine'

require 'cbfc/version'
require 'cbfc/ast/nodes'
require 'cbfc/parser'
require 'cbfc/transformer'
require 'cbfc/interpreter'
require 'cbfc/optimizer'
require 'cbfc/code_gen'

module Cbfc
  class Error < StandardError; end
end

