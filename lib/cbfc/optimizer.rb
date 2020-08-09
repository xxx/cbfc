# frozen_string_literal: true

# some peephole optimizations
module Cbfc
  class Optimizer
    def self.optimize(ops)
      result = ops
      length = result.length
      loop do
        result = optimize_pass(result)
        break if result.length == length

        length = result.length
      end
      result
    end

    def self.optimize_pass(ops)
      combine_operations(
        remove_canceling_operations(
          remove_adjacent_loops(ops)
        )
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

    def self.remove_canceling_operations(ops)
      result = ops

      ops.each_cons(2).with_index do |ab_pair, idx|
        # idx is a's index in the array here

        a, b = ab_pair

        next if a.nil? || b.nil?

        if (a.is_a?(Cbfc::Ast::IncPtr) && b.is_a?(Cbfc::Ast::DecPtr)) ||
           (a.is_a?(Cbfc::Ast::DecPtr) && b.is_a?(Cbfc::Ast::IncPtr)) ||
           (a.is_a?(Cbfc::Ast::DecVal) && b.is_a?(Cbfc::Ast::IncVal)) ||
           (a.is_a?(Cbfc::Ast::IncVal) && b.is_a?(Cbfc::Ast::DecVal))

          # they fully cancel each other out
          if a.count == b.count
            result[idx] = nil
            result[idx + 1] = nil
            next
          end

          sorted = [a, b].sort_by(&:count)

          less, more = sorted

          more.count -= less.count
          result[less == a ? idx : idx + 1] = nil
        end
      end

      result.compact
    end

    # Intended to be run after remove_canceling_operations
    def self.combine_operations(ops)
      result = ops

      ops.each_cons(2).with_index do |ab_pair, idx|
        # idx is a's index in the array here

        a, b = ab_pair

        next if a.nil? || b.nil?

        if (a.is_a?(Cbfc::Ast::IncPtr) && b.is_a?(Cbfc::Ast::IncPtr)) ||
           (a.is_a?(Cbfc::Ast::DecPtr) && b.is_a?(Cbfc::Ast::DecPtr)) ||
           (a.is_a?(Cbfc::Ast::IncVal) && b.is_a?(Cbfc::Ast::IncVal)) ||
           (a.is_a?(Cbfc::Ast::DecVal) && b.is_a?(Cbfc::Ast::DecVal))

          a.count += b.count
          result[idx] = nil if a.count.zero?
          result[idx + 1] = nil
        end
      end

      result.compact
    end
  end
end
