# frozen_string_literal: true

module Cbfc
  class BfNode < Object; end

  module Ast
    class Program < BfNode
      attr_reader :ops

      def initialize(ops)
        @ops = ops
      end

      def to_s
        "#{inspect}#{ops.map(&:inspect)}"
      end
    end

    class IncPtr < BfNode; end
    class DecPtr < BfNode; end
    class IncVal < BfNode; end
    class DecVal < BfNode; end
    class WriteByte < BfNode; end
    class ReadByte < BfNode; end

    class Loop < BfNode
      attr_reader :ops

      def initialize(ops)
        @ops = ops
      end

      def to_s
        "#{inspect}#{ops.map(&:inspect)}"
      end
    end
  end
end
