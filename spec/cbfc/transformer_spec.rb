# frozen_string_literal: true

RSpec.describe Cbfc::Transformer do
  describe 'inc_ptr' do
    it 'combines the ops into the AST count' do
      node = to_ast('>>>>>>', :inc_ptr)
      expect(node).to be_a(Cbfc::Ast::IncPtr)
      expect(node.count).to eq 6
    end
  end

  describe 'dec_ptr' do
    it 'combines the ops into the AST count' do
      node = to_ast('<<<<', :dec_ptr)
      expect(node).to be_a(Cbfc::Ast::DecPtr)
      expect(node.count).to eq 4
    end
  end

  describe 'inc_val' do
    it 'combines the ops into the AST count' do
      node = to_ast('+++++', :inc_val)
      expect(node).to be_a(Cbfc::Ast::IncVal)
      expect(node.count).to eq 5
    end
  end

  describe 'dec_val' do
    it 'combines the ops into the AST count' do
      node = to_ast('---', :dec_val)
      expect(node).to be_a(Cbfc::Ast::DecVal)
      expect(node.count).to eq 3
    end
  end

  describe 'write_byte' do
    it 'emits an AST node' do
      node = to_ast('.', :write_byte)
      expect(node).to be_a(Cbfc::Ast::WriteByte)
    end
  end

  describe 'read_byte' do
    it 'emits an AST node' do
      node = to_ast(',', :read_byte)
      expect(node).to be_a(Cbfc::Ast::ReadByte)
    end
  end

  describe 'zero_cell' do
    it 'emits an AST node' do
      node = to_ast('[-]', :zero_cell)
      expect(node).to be_a(Cbfc::Ast::ZeroCell)
    end
  end

  describe 'multiply_loop' do
    it 'emits an AST node with the index & multiplier pairs' do
      node = to_ast('[->>+++>++>>++++<<++<<+<]', :multiply_loop)
      expect(node).to be_a(Cbfc::Ast::MultiplyLoop)
      expect(node.offsets).to eq({ 2 => 3, 3 => 4, 5 => 4, 1 => 1 })
    end
  end

  describe 'negative_multiply_loop' do
    it 'emits an AST node with the index & multiplier pairs' do
      node = to_ast('[-<<+++<++<<++++>>++>>+>]', :negative_multiply_loop)
      expect(node).to be_a(Cbfc::Ast::MultiplyLoop)
      expect(node.offsets).to eq({ -2 => 3, -3 => 4, -5 => 4, -1 => 1 })
    end
  end

  describe 'loop_statement' do
    it 'emits an AST node with the contained ops' do
      node = to_ast('[>++<-[-][->>]]', :loop_statement)
      expect(node).to be_a(Cbfc::Ast::Loop)
      expect(node.ops.map(&:class)).to eq [
        Cbfc::Ast::IncPtr,
        Cbfc::Ast::IncVal,
        Cbfc::Ast::DecPtr,
        Cbfc::Ast::DecVal,
        Cbfc::Ast::ZeroCell,
        Cbfc::Ast::Loop
      ]
    end
  end

  describe 'program' do
    it 'emits an AST node with the contained ops' do
      node = to_ast('>-->[>++<-[-][->>]]', :program)
      expect(node).to be_a(Cbfc::Ast::Program)
      expect(node.ops.map(&:class)).to eq [
        Cbfc::Ast::IncPtr,
        Cbfc::Ast::DecVal,
        Cbfc::Ast::IncPtr,
        Cbfc::Ast::Loop
      ]
    end
  end
end
