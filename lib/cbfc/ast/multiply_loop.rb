# frozen_string_literal: true

module Cbfc
  module Ast
    class MultiplyLoop < LoopNode
      attr_reader :offsets, :ops

      def initialize(ops)
        @ops = ops
        generate_offsets
      end

      def generate_offsets
        @offsets = {}
        index = 0
        multiplier = 0

        ops.to_s.each_char do |op|
          case op
          when '>'
            if multiplier.positive?
              @offsets[index] ||= 0
              @offsets[index] += multiplier
              multiplier = 0
            end

            index += 1
          when '<'
            if multiplier.positive?
              @offsets[index] ||= 0
              @offsets[index] += multiplier
              multiplier = 0
            end

            index -= 1
          when '+'
            multiplier += 1
          end
        end
      end
    end
  end
end
