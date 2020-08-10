# frozen_string_literal: true

module Cbfc
  module Ast
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
  end
end
