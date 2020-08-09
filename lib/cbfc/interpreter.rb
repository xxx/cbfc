# frozen_string_literal: true

module Cbfc
  class Interpreter
    CELL_COUNT = CodeGen::CELL_COUNT

    DISPATCH_TABLE = CodeGen::DISPATCH_TABLE

    # Create a code generator targeting the C (C99) programming language.
    #
    # @param ast [Cbfc::Ast::Program] the AST of the program to compile
    # @param cell_count: Number of cells in the memory array. Defaults to 30,000.
    # @return [Cbfc::Interpreter] a new Interpreter instance
    def initialize(ast, cell_count: CELL_COUNT)
      @ast = ast
      @cell_count = cell_count
      @memory = Array.new(cell_count, 0)
      @ptr = 0
    end

    # Evaluate a node through the interpreter
    #
    # @param node [Cbfc::Ast::BfNode] An AST node to evaluate
    def eval(node = @ast)
      method = DISPATCH_TABLE.fetch(node.class)
      send(method, node)
    end

    private

    def program(node)
      node.ops.each { |op| eval(op) } # rubocop:disable Security/Eval
    end

    def inc_ptr(node)
      @ptr += node.count
      @ptr -= @cell_count while @ptr >= @cell_count
    end

    def dec_ptr(node)
      @ptr -= node.count
      @ptr += @cell_count while @ptr.negative?
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

    def multiply_loop(node)
      node.offsets.each do |offset, multiplier|
        @memory[@ptr + offset] += (@memory[@ptr] * multiplier)
      end

      @memory[@ptr] = 0
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
