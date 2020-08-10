# frozen_string_literal: true

require 'forwardable'
require 'parslet'
require 'llvm/core'
require 'llvm/execution_engine'

require 'cbfc/version'

require 'cbfc/ast/bf_node'
require 'cbfc/ast/count_node'
require 'cbfc/ast/loop_node'
require 'cbfc/ast/dec_ptr'
require 'cbfc/ast/dec_val'
require 'cbfc/ast/inc_ptr'
require 'cbfc/ast/inc_val'
require 'cbfc/ast/loop'
require 'cbfc/ast/multiply_loop'
require 'cbfc/ast/program'
require 'cbfc/ast/read_byte'
require 'cbfc/ast/scan_left'
require 'cbfc/ast/scan_right'
require 'cbfc/ast/write_byte'
require 'cbfc/ast/zero_cell'

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
