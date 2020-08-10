# frozen_string_literal: true

module Cbfc
  module Ast
    class BfNode
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
  end
end
