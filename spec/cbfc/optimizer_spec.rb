# frozen_string_literal: true

RSpec.describe Cbfc::Optimizer do
  describe '.remove_adjacent_loops' do
    it 'removes all loops immediately after a first one in an ops list' do
      ast = to_ast('[--][->>][<<>>>><>><>]+[>>]')
      expect(described_class.remove_adjacent_loops(ast.ops).map(&:class)).to(
        eq [Cbfc::Ast::Loop, Cbfc::Ast::IncVal, Cbfc::Ast::Loop]
      )
    end
  end

  describe '.remove_canceling_operations' do
    it 'cancels any directly competing incs and decs' do
      ast = to_ast('>>>><<<<<<')
      optimized = described_class.remove_canceling_operations(ast.ops)

      expect(optimized.map(&:class)).to(
        eq [Cbfc::Ast::DecPtr]
      )
      expect(optimized.first.count).to eq 2
    end

    it 'cancels any directly competing incs and decs' do
      ast = to_ast('+++++--')
      optimized = described_class.remove_canceling_operations(ast.ops)

      expect(optimized.map(&:class)).to(
        eq [Cbfc::Ast::IncVal]
      )
      expect(optimized.first.count).to eq 3
    end

    it 'handles chains' do
      ast = to_ast('++++--------++')
      optimized = described_class.remove_canceling_operations(ast.ops)

      expect(optimized.map(&:class)).to(
        eq [Cbfc::Ast::DecVal]
      )
      expect(optimized.first.count).to eq 2
    end

    it 'does not add a node if they completely cancel each other' do
      ast = to_ast('++++--------++++')
      optimized = described_class.remove_canceling_operations(ast.ops)

      expect(optimized.map(&:class)).to eq []
    end

    it 'handles multiple types' do
      ast = to_ast('++++--------++>><>>>+-')
      optimized = described_class.remove_canceling_operations(ast.ops)

      expect(optimized.map(&:class)).to(
        eq [
          Cbfc::Ast::DecVal,
          Cbfc::Ast::IncPtr,
          Cbfc::Ast::IncPtr
        ]
      )
      expect(optimized.map(&:count)).to eq [2, 1, 3]
    end
  end

  describe '.combine_operations' do
    it 'does a single pass of combining like operations if they occur after other optimizations' do
      ast = to_ast('>><>><>>>><>+-')
      optimized = described_class.remove_canceling_operations(ast.ops)
      optimized = described_class.combine_operations(optimized)

      expect(optimized.map(&:class)).to eq [Cbfc::Ast::IncPtr, Cbfc::Ast::IncPtr, Cbfc::Ast::IncPtr]
      expect(optimized.map(&:count)).to eq [2, 3, 1]
    end
  end
end
