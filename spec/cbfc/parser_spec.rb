# frozen_string_literal: true

require 'parslet/rig/rspec'

RSpec.describe Cbfc::Parser do
  subject { described_class.new }

  describe 'inc_ptr' do
    it 'parses inc_ptr operations' do
      expect(subject.inc_ptr).to parse('>')
      expect(subject.inc_ptr).to parse('>>>>>')
      expect(subject.inc_ptr).not_to parse('>>>>><')
      expect(subject.inc_ptr).not_to parse('')
    end
  end

  describe 'dec_ptr' do
    it 'parses dec_ptr operations' do
      expect(subject.dec_ptr).to parse('<')
      expect(subject.dec_ptr).to parse('<<<<<')
      expect(subject.dec_ptr).not_to parse('<<<<<>')
      expect(subject.dec_ptr).not_to parse('')
    end
  end

  describe 'inc_val' do
    it 'parses inc_val operations' do
      expect(subject.inc_val).to parse('+')
      expect(subject.inc_val).to parse('+++++')
      expect(subject.inc_val).not_to parse('+++++-')
      expect(subject.inc_val).not_to parse('')
    end
  end

  describe 'dec_val' do
    it 'parses dec_val operations' do
      expect(subject.dec_val).to parse('-')
      expect(subject.dec_val).to parse('-----')
      expect(subject.dec_val).not_to parse('-----+')
      expect(subject.dec_val).not_to parse('')
    end
  end

  describe 'write_byte' do
    it 'parses write_byte operations' do
      expect(subject.write_byte).to parse('.')
      expect(subject.write_byte).not_to parse('..')
      expect(subject.write_byte).not_to parse('.>')
      expect(subject.write_byte).not_to parse('')
    end
  end

  describe 'read_byte' do
    it 'parses read_byte operations' do
      expect(subject.read_byte).to parse(',')
      expect(subject.read_byte).to parse('-,')
      expect(subject.read_byte).to parse('-+,')
      expect(subject.read_byte).to parse('-+-+-+foo,')
      expect(subject.read_byte).not_to parse(',,')
      expect(subject.read_byte).not_to parse(',>')
      expect(subject.read_byte).not_to parse('')
    end
  end

  describe 'zero_cell' do
    it 'parses zero_cell operations' do
      expect(subject.zero_cell).to parse('[-]')
      expect(subject.zero_cell).to parse('[+]')
      expect(subject.zero_cell).not_to parse('[>]')
      expect(subject.zero_cell).not_to parse('')
    end
  end

  describe 'multiply_loop' do
    it 'parses loops that multiply cells to the right of the pointer' do
      expect(subject.multiply_loop).to parse('[->+<]')
      expect(subject.multiply_loop).to parse("[->\n+>+<<]")
      expect(subject.multiply_loop).to parse('[->>>+<<<]')
      expect(subject.multiply_loop).to parse('[->>+>+>+<<<<]')
      expect(subject.multiply_loop).to parse('[->>+++>++>+>>+<<<<<<]')
      expect(subject.multiply_loop).to parse('[->++++<]')
      expect(subject.multiply_loop).to parse('[->>++++<+<]')
      expect(subject.multiply_loop).not_to parse('[-<<+<+<+>>>>]')
      expect(subject.multiply_loop).not_to parse('')
    end
  end

  describe 'negative_multiply_loop' do
    it 'parses loops that multiply cells to the left of the pointer' do
      expect(subject.negative_multiply_loop).to parse('[-<+>]')
      expect(subject.negative_multiply_loop).to parse("[-<\n+<+>>]")
      expect(subject.negative_multiply_loop).to parse('[-<<<+>>>]')
      expect(subject.negative_multiply_loop).to parse('[-<<+<+<+>>>>]')
      expect(subject.negative_multiply_loop).to parse('[-<<+++<++<+<<+>>>>>>]')
      expect(subject.negative_multiply_loop).to parse('[-<++++>]')
      expect(subject.negative_multiply_loop).to parse('[-<<++++>+>]')
      expect(subject.negative_multiply_loop).not_to parse('[->>+>+>+<<<<]')
      expect(subject.negative_multiply_loop).not_to parse('')
    end
  end

  describe 'loop_statement' do
    it 'parses non-optimized loops' do
      expect(subject.loop_statement).to parse('[alsd>><<<<>++-++]')
      # negative multiply loop is parsable here too, but grammar has lower priority for this rule.
      expect(subject.loop_statement).to parse('[-<+>]')
      expect(subject.loop_statement).not_to parse('[alsd>><<<<>++-++]]')
      expect(subject.loop_statement).not_to parse('')
    end
  end

  describe 'statement' do
    it 'parses statements' do
      expect(subject.statement).to parse('>>>')
      expect(subject.statement).to parse('<<<')
      expect(subject.statement).to parse('++')
      expect(subject.statement).to parse('--')
      expect(subject.statement).to parse('.')
      expect(subject.statement).to parse(',')
      expect(subject.statement).to parse('[-]')
      expect(subject.statement).to parse('[->+<]')
      expect(subject.statement).to parse('[-<+>]')
      expect(subject.statement).to parse('[++<>><<><+----]')

      expect(subject.statement).not_to parse('><')
      expect(subject.statement).not_to parse('')
    end
  end

  describe 'program' do
    it 'parses programs' do
      hello_world = <<~BF
        ++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.
      BF

      expect(subject.program).to parse(hello_world)

      expect(subject.statement).not_to parse('')
    end

    it 'correctly parses the read_byte optimization' do
      str = '++,>'

      expect(subject.program).to parse(str)
      parsed = subject.program.parse(str)
      expect(parsed.fetch(:program).first).to have_key(:read_byte)
    end
  end
end
