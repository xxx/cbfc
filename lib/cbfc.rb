# frozen_string_literal: true

require 'forwardable'
require 'parslet'
require 'llvm/core'
require 'llvm/execution_engine'

require 'cbfc/version'
require 'cbfc/ast/nodes'
require 'cbfc/parser'
require 'cbfc/transformer'
require 'cbfc/code_gen'
require 'cbfc/interpreter'
require 'cbfc/optimizer'
require 'cbfc/llvm_code_gen'
require 'cbfc/c_code_gen'

module Cbfc
  class Error < StandardError; end

  module MemrchrChecker
    extend FFI::Library
    ffi_lib 'c'
    HAS_MEMRCHR = begin
                    attach_function(:memrchr, %i[pointer int size_t], :pointer) && true
                  rescue FFI::NotFoundError
                    false
                  end
  end
end
