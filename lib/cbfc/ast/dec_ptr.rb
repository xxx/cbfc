# frozen_string_literal: true

module Cbfc
  module Ast
    class DecPtr < CountNode
      private

      def opposing_type
        IncPtr
      end
    end
  end
end
