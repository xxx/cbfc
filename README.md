# Cbfc

##### A crappy brainfuck compiler and interpreter to get some experience targeting LLVM.

## Installation

**Note** This gem requires LLVM version 10 to be installed. If the gem and its dependencies
install without error, you're probably all set.

Add this line to your application's Gemfile:

```ruby
gem 'cbfc'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install cbfc

## Usage

```ruby
# Create an AST from a file:
parsed = Cbfc::Parser.parse_file(ARGV[0])
ast = Cbfc::Transformer.new.apply(parsed)

# Interpret via Ruby Interpreter (slow)
interpreter = Cbfc::Interpreter.new(ast)
interpreter.eval

#
# All Further usages require (in-memory) code generation:
#
code_gen = Cbfc::CodeGen.new(ast)
code_gen.compile

# Interpret via LLVM Interpreter (fast))
code_gen.interpret_jit

# Emit the IR for the compiled file
code_gen.to_s

# Emit the IR to a file
code_gen.to_file(path)

# Emit LLVM bitcode to a file
code_gen.to_bitcode(path)
```

To compile to a native binary, I've been using the following very janky method:

1. Emit an IR or bitcode file somewhere.
1. `llc <my_file.ll> -filetype=obj -O3 --relocation-model=pic -o my_file.o`
1. `gcc my_file.o -o my_file`

The gem's `bin` directory has a few scripts in it that might be useful for those who
just want to interpret or compile some files, without having to write code.

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake spec` to run the tests. You can also run `bin/console`
for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and
then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/xxx/cbfc.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
