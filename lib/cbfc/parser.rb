# frozen_string_literal: true

module Cbfc
  class Parser < Parslet::Parser
    rule(:inc_ptr) { str('>').as(:inc_ptr) }
    rule(:dec_ptr) { str('<').as(:dec_ptr) }
    rule(:inc_val) { str('+').as(:inc_val) }
    rule(:dec_val) { str('-').as(:dec_val) }
    rule(:write_byte) { str('.').as(:write_byte) }
    rule(:read_byte) { str(',').as(:read_byte) }
    rule(:loop_start) { str('[').as(:loop_start) }
    rule(:loop_end) { str(']').as(:loop_end) }

    rule(:junk) { match('[^><+\.,\[\]-]').repeat(1) }
    rule(:junk?) { junk.maybe }

    rule(:loop_statement) { loop_start >> junk? >> statement.repeat.as(:loop) >> loop_end }
    rule(:statement) do
      (inc_ptr | dec_ptr | inc_val | dec_val | write_byte | read_byte | loop_statement) >> junk?
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
