# frozen_string_literal: true

# some peephole optimizations
module Cbfc
  class Optimizer
    # Recursively handles optimizing a full tree
    def self.recursive_optimize(ast)
      return ast unless ast.respond_to?(:ops)

      optimized = optimize(ast.ops)

      optimized.each do |operation|
        operation.ops = optimize(operation.ops) if operation.respond_to?(:ops)
      end

      optimized
    end

    # Optimize a single ops list, without recursing into loops
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
      result = []
      length = list.length

      # This loops until everything is combined.
      loop do
        list.each_slice(2) do |ab_pair|
          a, b = ab_pair
          combined = b.nil? ? [a] : a.combine(b)
          result.concat(combined)
        end

        break if result.length == length

        length = result.length
        list = result
        result = []
      end

      result
    end
  end
end
