# frozen_string_literal: true

RSpec.describe Cbfc do
  it 'parses simple programs' do
    hello_world = <<~BF
      ++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.
    BF

    expect do
      parsed = Cbfc::Parser.new.parse(hello_world)
      ast = Cbfc::Transformer.new.apply(parsed)
      Cbfc::LlvmCodeGen.new(ast).compile
    end.not_to raise_error
  end
end
