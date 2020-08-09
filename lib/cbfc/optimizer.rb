# frozen_string_literal: true

# some peephole optimizations
module Cbfc
  class Optimizer
    # Recursively handles optimizing a full tree
    # This method updates the AST in-place.
    def self.recursive_optimize!(ast)
      return ast unless ast.respond_to?(:ops)

      ast.ops = optimize(ast.ops)

      ast.ops.each do |operation|
        operation.ops = optimize(operation.ops) if operation.respond_to?(:ops)
      end

      ast
    end

    # Optimize a single ops list, without recursing into loops
    # Single passes will not change the ops
    def self.optimize(ops)
      combine_nodes(
        remove_adjacent_loops(ops)
      )
    end

    def self.remove_adjacent_loops(ops)
      result = []
      current_loop = nil
      ops.each do |op|
        if op.is_a? Cbfc::Ast::LoopNode
          next if current_loop

          current_loop = op
        else
          current_loop = nil
        end

        result << op
      end

      result
    end

    def self.combine_nodes(ops)
      list = ops
      length = list.length
      result = []

      # This loops until everything is combined.
      loop do
        list.each_slice(2) do |a, b|
          combined = b.nil? ? [a] : a.combine(b)
          result.concat(combined)
        end

        break if result.length == length

        list = result
        length = result.length
        result = []
      end

      result
    end
  end
end
