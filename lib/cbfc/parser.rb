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

    # handle copying bytes in front of the pointer
    rule(:copy_core) { str('>') >> junk? >> str('+') >> junk? >> str('<') }
    rule(:copy_body) { str('>') >> junk? >> str('+').maybe >> copy_body >> junk? >> str('<') | copy_core }
    rule(:copy_loop) { loop_start >> junk? >> str('-') >> junk? >> copy_body.as(:copy_loop) >> loop_end }

    # handle copying bytes behind the pointer
    rule(:negative_copy_core) { str('<') >> junk? >> str('+') >> junk? >> str('>') }
    rule(:negative_copy_body) do
      str('<') >> junk? >> str('+').maybe >> negative_copy_body >> junk? >> str('>') | negative_copy_core
    end
    rule(:negative_copy_loop) do
      loop_start >> junk? >> str('-') >> junk? >> negative_copy_body.as(:negative_copy_loop) >> loop_end
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
        copy_loop |
        negative_copy_loop |
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
