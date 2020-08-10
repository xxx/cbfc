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
    rule(scan_right: simple(:op)) { Ast::ScanRight.new }
    rule(scan_left: simple(:op)) { Ast::ScanLeft.new }

    # Use the same node type for both kinds of multiply loops -
    # negative ends up with negative indices
    rule(multiply_loop: simple(:ops)) { Ast::MultiplyLoop.new(ops) }
    rule(negative_multiply_loop: simple(:ops)) { Ast::MultiplyLoop.new(ops) }

    rule(loop: sequence(:loop_ops)) { Ast::Loop.new(loop_ops) }

    rule(program: sequence(:ops)) { Ast::Program.new(ops) }
  end
end
