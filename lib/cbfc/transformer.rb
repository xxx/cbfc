# frozen_string_literal: true

module Cbfc
  class Transformer < Parslet::Transform
    rule(inc_ptr: '>') { Ast::IncPtr.new }
    rule(dec_ptr: '<') { Ast::DecPtr.new }
    rule(inc_val: '+') { Ast::IncVal.new }
    rule(dec_val: '-') { Ast::DecVal.new }
    rule(write_byte: '.') { Ast::WriteByte.new }
    rule(read_byte: ',') { Ast::ReadByte.new }

    rule(
      loop_start: '[',
      loop: sequence(:loop_ops),
      loop_end: ']'
    ) { Ast::Loop.new(loop_ops) }

    rule(program: sequence(:ops)) { Ast::Program.new(ops) }
  end
end
