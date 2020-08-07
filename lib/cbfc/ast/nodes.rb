# frozen_string_literal: true

module Cbfc
  class BfNode < Object; end
  class CountNode < BfNode
    attr_reader :count
    def initialize(count)
      @count = count
    end
  end

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

    class IncPtr < CountNode; end
    class DecPtr < CountNode; end
    class IncVal < CountNode; end
    class DecVal < CountNode; end
    class WriteByte < BfNode; end
    class ReadByte < BfNode; end

    class ZeroCell < BfNode; end

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
