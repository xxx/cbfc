# frozen_string_literal: true

module Cbfc
  class Transformer < Parslet::Transform
    rule(inc_ptr: subtree(:ops)) { Ast::IncPtr.new(ops.length) }
    rule(dec_ptr: subtree(:ops)) { Ast::DecPtr.new(ops.length) }
    rule(inc_val: subtree(:ops)) { Ast::IncVal.new(ops.length) }
    rule(dec_val: subtree(:ops)) { Ast::DecVal.new(ops.length) }
    rule(write_byte: '.') { Ast::WriteByte.new }
    rule(read_byte: ',') { Ast::ReadByte.new }

    rule(zero_cell: simple(:op)) { Ast::ZeroCell.new }

    # Use the same node type for both kinds of copy loops -
    # negative ends up with negative indices
    rule(copy_loop: simple(:ops)) { Ast::CopyLoop.new(ops) }
    rule(negative_copy_loop: simple(:ops)) { Ast::CopyLoop.new(ops) }

    rule(loop: sequence(:loop_ops)) { Ast::Loop.new(loop_ops) }

    rule(program: sequence(:ops)) { Ast::Program.new(ops) }
  end
end
