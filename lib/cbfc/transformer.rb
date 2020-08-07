# frozen_string_literal: true

module Cbfc
  class Transformer < Parslet::Transform
    rule(inc_ptr: subtree(:ops)) { Ast::IncPtr.new(ops.length) }
    rule(dec_ptr: subtree(:ops)) { Ast::DecPtr.new(ops.length) }
    rule(inc_val: subtree(:ops)) { Ast::IncVal.new(ops.length) }
    rule(dec_val: subtree(:ops)) { Ast::DecVal.new(ops.length) }
    rule(write_byte: '.') { Ast::WriteByte.new }
    rule(read_byte: ',') { Ast::ReadByte.new }

    rule(
      loop_start: '[',
      loop: '-',
      loop_end: ']'
    ) { Ast::ZeroCell.new }

    rule(
      loop_start: '[',
      loop: sequence(:loop_ops),
      loop_end: ']'
    ) { Ast::Loop.new(loop_ops) }

    rule(program: sequence(:ops)) { Ast::Program.new(ops) }
  end
end
