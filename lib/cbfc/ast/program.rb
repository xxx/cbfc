# frozen_string_literal: true

module Cbfc
  module Ast
    class Program < BfNode
      attr_accessor :ops

      def initialize(ops)
        @ops = ops
      end

      def optimize
        # Remove all loops in the program that occur before
        # any values are set, as it means all cells are 0.
        value_set = false
        @ops = ops.select do |op|
          next false if op.is_a?(Ast::LoopNode) && !value_set

          case op
          when Ast::IncVal, Ast::DecVal, Ast::ReadByte
            value_set = true
          end

          true
        end

        @ops = Cbfc::Optimizer.optimize(ops)

        ops.each(&:optimize)
      end

      def to_s
        "#{inspect}#{ops.map(&:inspect)}"
      end
    end
  end
end
