# frozen_string_literal: true

module Cbfc
  module Ast
    class IncVal < CountNode
      private

      def opposing_type
        DecVal
      end
    end
  end
end
