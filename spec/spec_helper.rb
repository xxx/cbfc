# frozen_string_literal: true

require 'bundler/setup'
require 'cbfc'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def to_ast(string, parser_rule = :program)
  parsed = Cbfc::Parser.new.public_send(parser_rule).parse(string)
  Cbfc::Transformer.new.apply(parsed)
end

