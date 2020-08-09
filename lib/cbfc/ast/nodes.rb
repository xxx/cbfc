# frozen_string_literal: true

module Cbfc
  module Ast
    class BfNode < Object; end
    class CountNode < BfNode
      attr_accessor :count
      def initialize(count)
        @count = count
      end
    end
    class LoopNode < BfNode; end

    class Program < BfNode
      attr_reader :ops

      def initialize(ops)
        @ops = Cbfc::Optimizer.optimize(ops)
      end

      def to_s
        "#{inspect}#{ops.map(&:inspect)}"
      end
    end

    class IncPtr < CountNode; end
    class DecPtr < CountNode; end
    class IncVal < CountNode; end
    class DecVal < CountNode; end
    class WriteByte < BfNode; end
    class ReadByte < BfNode; end

    class MultiplyLoop < LoopNode
      attr_reader :offsets

      def initialize(ops)
        @ops = ops
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

    class ZeroCell < LoopNode; end

    class Loop < LoopNode
      attr_reader :ops

      def initialize(ops)
        @ops = Cbfc::Optimizer.optimize(ops)
      end

      def to_s
        "#{inspect}#{ops.map(&:inspect)}"
      end
    end
  end
end
