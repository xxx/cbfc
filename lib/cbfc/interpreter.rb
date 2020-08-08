# frozen_string_literal: true

module Cbfc
  class Interpreter
    CELL_COUNT = 30_000

    DISPATCH_TABLE = {
      Ast::Program => :program,
      Ast::IncPtr => :inc_ptr,
      Ast::DecPtr => :dec_ptr,
      Ast::IncVal => :inc_val,
      Ast::DecVal => :dec_val,
      Ast::WriteByte => :write_byte,
      Ast::ReadByte => :read_byte,
      Ast::ZeroCell => :zero_cell,
      Ast::Loop => :do_loop
    }.freeze

    def initialize(ast, cell_count: CELL_COUNT)
      @ast = ast
      @data_size = cell_count
      @memory = Array.new(cell_count, 0)
      @ptr = 0
    end

    def eval(node = @ast)
      method = DISPATCH_TABLE.fetch(node.class)
      send(method, node)
    end

    def program(node)
      node.ops.each { |op| eval(op) } # rubocop:disable Security/Eval
    end

    def inc_ptr(node)
      @ptr += node.count
      @ptr -= @data_size while @ptr >= @data_size
    end

    def dec_ptr(node)
      @ptr -= node.count
      @ptr += @data_size while @ptr.negative?
    end

    def inc_val(node)
      @memory[@ptr] += node.count
    end

    def dec_val(node)
      @memory[@ptr] -= node.count
    end

    def write_byte(_)
      $stdout.putc @memory[@ptr]
    end

    def read_byte(_)
      @memory[@ptr] = $stdin.getc.ord
    end

    def zero_cell(_)
      @memory[@ptr] = 0
    end

    def do_loop(node)
      loop do
        return if @memory[@ptr].zero?

        node.ops.each { |op| eval(op) } # rubocop:disable Security/Eval
      end
    end
  end
end
