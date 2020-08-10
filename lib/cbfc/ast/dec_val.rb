# frozen_string_literal: true

module Cbfc
  module Ast
    class DecVal < CountNode
      private

      def opposing_type
        IncVal
      end
    end
  end
end
