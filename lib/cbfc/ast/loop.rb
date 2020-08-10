# frozen_string_literal: true

module Cbfc
  module Ast
    class Loop < LoopNode
      attr_accessor :ops

      def initialize(ops)
        @ops = ops
      end

      def optimize
        @ops = Cbfc::Optimizer.optimize(ops)
        ops.each(&:optimize)
      end

      def to_s
        "#{inspect}#{ops.map(&:inspect)}"
      end
    end
  end
end
