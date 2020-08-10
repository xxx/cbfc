# frozen_string_literal: true

# shared code used by the various code generators and interpreter
module Cbfc
  module CodeGen
    # default cell count
    CELL_COUNT = 30_000

    # code generators and interpreter use the same dispatch table
    DISPATCH_TABLE = {
      Ast::Program => :program,
      Ast::IncPtr => :inc_ptr,
      Ast::DecPtr => :dec_ptr,
      Ast::IncVal => :inc_val,
      Ast::DecVal => :dec_val,
      Ast::WriteByte => :write_byte,
      Ast::ReadByte => :read_byte,
      Ast::MultiplyLoop => :multiply_loop,
      Ast::ScanLeft => :scan_left,
      Ast::ScanRight => :scan_right,
      Ast::ZeroCell => :zero_cell,
      Ast::Loop => :do_loop
    }.freeze

    NATIVE_BITS = FFI.type_size(:int) * 8
    SIZE_T_BITS = FFI.type_size(:size_t) * 8
    SIZE_T = Object.const_get("LLVM::Int#{SIZE_T_BITS}")
  end
end
