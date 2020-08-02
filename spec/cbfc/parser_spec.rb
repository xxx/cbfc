# frozen_string_literal: true

RSpec.describe Cbfc::Parser do
  it 'parses simple programs' do
    hello_world = <<~BF
      ++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.
    BF

    parsed = described_class.new.parse(hello_world)

    # pp parsed

    ast = Cbfc::Transformer.new.apply(parsed)

    # pp transformed

    interpreter = Cbfc::Interpreter.new(ast)

    interpreter.eval
  end
end
