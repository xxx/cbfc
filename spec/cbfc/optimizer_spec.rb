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

  describe '.combine_nodes' do
    context 'opposing nodes' do
      it 'cancels any directly competing incs and decs' do
        ast = to_ast('>>>><<<<<<')
        optimized = described_class.combine_nodes(ast.ops)

        expect(optimized.map(&:class)).to(
          eq [Cbfc::Ast::DecPtr]
        )
        expect(optimized.first.count).to eq 2
      end

      it 'cancels any directly competing incs and decs' do
        ast = to_ast('+++++--')
        optimized = described_class.combine_nodes(ast.ops)

        expect(optimized.map(&:class)).to(
          eq [Cbfc::Ast::IncVal]
        )
        expect(optimized.first.count).to eq 3
      end

      it 'handles chains' do
        ast = to_ast('++++--------++')
        optimized = described_class.combine_nodes(ast.ops)

        expect(optimized.map(&:class)).to(
          eq [Cbfc::Ast::DecVal]
        )
        expect(optimized.first.count).to eq 2
      end

      it 'does not add a node if they completely cancel each other' do
        ast = to_ast('++++--------++++')
        optimized = described_class.combine_nodes(ast.ops)

        expect(optimized.map(&:class)).to eq []
      end

      it 'handles multiple types' do
        ast = to_ast('++++--------++>><>>>+-')
        optimized = described_class.combine_nodes(ast.ops)

        expect(optimized.map(&:class)).to(
          eq [
               Cbfc::Ast::DecVal,
               Cbfc::Ast::IncPtr
             ]
        )
        expect(optimized.map(&:count)).to eq [2, 4]
      end
    end

    context 'same nodes' do
      it 'combines nodes of the same count type ' do
        ast = to_ast('>><>><>>>><>+-')
        optimized = described_class.combine_nodes(ast.ops)

        expect(optimized.map(&:class)).to eq [Cbfc::Ast::IncPtr]
        expect(optimized.map(&:count)).to eq [6]
      end
    end
  end
end
