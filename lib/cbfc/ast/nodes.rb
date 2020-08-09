# frozen_string_literal: true

module Cbfc
  module Ast
    class BfNode < Object
      # potentially combine this node with another node
      #
      # @param other [Cbfc::Ast::BfNode] the other node to check against
      # @return [Array<Cbfc::Ast::BfNode>] An array with a single node if
      #   a combination occurred, or both nodes if they could not be combined.
      def combine(other)
        [self, other]
      end
    end

    class CountNode < BfNode
      attr_accessor :count
      def initialize(count)
        @count = count
      end

      def combine(other)
        nodes = if other.is_a?(self.class)
                  @count += other.count
                  [self]
                elsif other.is_a?(opposing_type)
                  if count > other.count
                    @count -= other.count
                    [self]
                  else
                    other.count -= count
                    [other]
                  end
                else
                  [self, other]
                end

        nodes.reject { |node| node.respond_to?(:count) && node.count.zero? }
      end

      private

      def opposing_type
        nil
      end
    end

    class LoopNode < BfNode; end

    class Program < BfNode
      attr_accessor :ops

      def initialize(ops)
        @ops = ops
      end

      def to_s
        "#{inspect}#{ops.map(&:inspect)}"
      end
    end

    class IncPtr < CountNode
      private

      def opposing_type
        DecPtr
      end
    end

    class DecPtr < CountNode
      private

      def opposing_type
        IncPtr
      end
    end

    class IncVal < CountNode
      private

      def opposing_type
        DecVal
      end
    end

    class DecVal < CountNode
      private

      def opposing_type
        IncVal
      end
    end

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
      attr_accessor :ops

      def initialize(ops)
        # @ops = Cbfc::Optimizer.optimize(ops)
        @ops = ops
      end

      def to_s
        "#{inspect}#{ops.map(&:inspect)}"
      end
    end
  end
end
