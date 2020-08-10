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

      # A hook to allow a node to optimize itself or its children
      # It's expected that this will update the node in-place.
      def optimize; end
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

    class ScanLeft < BfNode; end
    class ScanRight < BfNode; end
    class ZeroCell < LoopNode; end

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
