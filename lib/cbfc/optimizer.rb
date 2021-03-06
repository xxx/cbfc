# frozen_string_literal: true

# some peephole optimizations
module Cbfc
  class Optimizer
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
