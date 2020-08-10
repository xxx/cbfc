# frozen_string_literal: true

module Cbfc
  module Ast
    class IncPtr < CountNode
      private

      def opposing_type
        DecPtr
      end
    end
  end
end
