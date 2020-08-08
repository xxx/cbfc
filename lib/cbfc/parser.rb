# frozen_string_literal: true

module Cbfc
  class Parser < Parslet::Parser
    rule(:inc_ptr) { (str('>').as(:op) >> (str('>').as(:op) | junk).repeat(0)).as(:inc_ptr) }
    rule(:dec_ptr) { (str('<').as(:op) >> (str('<').as(:op) | junk).repeat(0)).as(:dec_ptr) }
    rule(:inc_val) { (str('+').as(:op) >> (str('+').as(:op) | junk).repeat(0)).as(:inc_val) }
    rule(:dec_val) { (str('-').as(:op) >> (str('-').as(:op) | junk).repeat(0)).as(:dec_val) }
    rule(:write_byte) { str('.').as(:write_byte) }
    rule(:read_byte) { str(',').as(:read_byte) }
    rule(:loop_start) { str('[') }
    rule(:loop_end) { str(']') }

    rule(:junk) { match('[^><+\.,\[\]-]').repeat(1) }
    rule(:junk?) { junk.maybe }

    # handle copying (w/ optional multiplication) bytes in front of the pointer
    rule(:multiply_core) { str('>') >> junk? >> str('+').repeat(1) >> junk? >> str('<') }
    rule(:multiply_body) do
      str('>') >> junk? >> str('+').repeat(0) >> multiply_body >> junk? >> str('<') | multiply_core
    end
    rule(:multiply_loop) { loop_start >> junk? >> str('-') >> junk? >> multiply_body.as(:multiply_loop) >> loop_end }

    # handle copying (w/ optional multiplication) bytes behind the pointer
    rule(:negative_multiply_core) { str('<') >> junk? >> str('+').repeat(1) >> junk? >> str('>') }
    rule(:negative_multiply_body) do
      str('<') >> junk? >> str('+').repeat(0) >> negative_multiply_body >> junk? >> str('>') | negative_multiply_core
    end
    rule(:negative_multiply_loop) do
      loop_start >> junk? >> str('-') >> junk? >> negative_multiply_body.as(:negative_multiply_loop) >> loop_end
    end

    rule(:zero_cell) { loop_start >> junk? >> match('[+-]').as(:zero_cell) >> junk? >> loop_end }
    rule(:loop_statement) { loop_start >> junk? >> statement.repeat.as(:loop) >> loop_end }
    rule(:statement) do
      (
        inc_ptr |
        dec_ptr |
        inc_val |
        dec_val |
        write_byte |
        read_byte |
        zero_cell |
        multiply_loop |
        negative_multiply_loop |
        loop_statement
      ) >> junk?
    end
    rule(:program) { junk? >> statement.repeat.as(:program) }

    root :program

    def self.parse_file(path)
      new.parse(File.read(path))
    rescue Parslet::ParseFailed => e
      warn e.parse_failure_cause.ascii_tree
    end
  end
end
