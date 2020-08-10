# Cbfc

##### A crappy Brainfuck compiler and interpreter to get some experience targeting LLVM.

Some differences from the standard - the Ruby interpreter uses BigInts and wraps memory.
The LLVM and C code generators are configurable in this regard, but default to the
traditional 8 bit cells and no memory wrapping.

This project incorporates a number of optimizations suggested at
http://calmerthanyouare.org/2015/01/07/optimizing-brainfuck.html. 

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

# Optionally run some peephole optimizations...
ast.optimize

# Interpret via Ruby Interpreter (slow)
interpreter = Cbfc::Interpreter.new(ast)
interpreter.eval

#
# All Further usages require (in-memory) code generation:
#
llvm_gen = Cbfc::LlvmCodeGen.new(ast)
llvm_gen.compile

# Interpret via LLVM Interpreter (fast))
llvm_gen.interpret_jit

# Emit the IR for the compiled file
llvm_gen.to_s

# Emit the IR to a file
llvm_gen.to_file(path)

# Emit LLVM bitcode to a file
llvm_gen.to_bitcode(path)

#
# Output as C is also possible:
#
File.open('my_file.c', 'wb') do |f|
  Cbfc::CCodeGen.new(ast, f).compile
end

# or...

io = StringIO.new
Cbfc::CCodeGen.new(ast, io).compile
io.string # the C source as a string
```

To compile the LLVM IR or bitcode to a native binary, I've been using the following rather janky method:

1. Emit your IR or bitcode file somewhere.
1. `llc <my_file.ll> -filetype=obj -O3 --relocation-model=pic -o my_file.o`
1. `gcc my_file.o -o my_file`

The gem's `bin` directory has a few scripts in it that might be useful for those who
just want to interpret or compile some files, without having to write code.

The cell width and count is configurable on the code generators:  
`Cbfc::LlvmCodeGen.new(ast, cell_count: 50000, cell_width: 8)`  
Cell widths of 8, 16, 32, 64, and 128 bits are supported. 8-bit ints are used by default,
and the cell count defaults to 30,000. 128 bit-widths are not available when generating
C code with the `Cbfc::CCodeGen` class. 

Memory wrap checking is configurable on the code generators:
`Cbfc::LlvmCodeGen.new(ast, enable_memory_wrap: false)`
Setting `enable_memory_wrap` to false will disable checking for, and doing, any memory
wrapping in the program, which can result in a significant performance increase, but
will lead to undefined behavior and possible segfaults if memory is read or written
to beyond the ends of the array. This only has occurred when compiled with optimizations.
`enable_memory_wrap` defaults to false.   

### /bin scripts

Some of the scripts in the /bin directory of the gem may be useful. `interpreter` is
a (slow) pure-Ruby Brainfuck interpreter. `interpreter-jit` will compile a file to
LLVM IR, then run it through its JIT-enabled interpreter. It's much faster than the
the Ruby interpreter.

The `compiler` script takes in a Brainfuck file and can emit a number of different formats:
```
Usage: ./compiler <infile> <outfile>
Output filename determines format:
  end with .ll - file emitted as LLVM IR
  end with .bc - file emitted as LLVM bitcode
  end with .c - file emitted as C source code
  end with .s - file emitted as assembly language for the target machine
  end with .o - file emitted as an object file
  "parse" - emit the parse tree to stdout
  "ast" - emit the AST to stdout
  "-" - emits LLVM IR to stdout
  anything else - emits an executable with that name
```
`compiler` makes a number of assumptions on what and where some things are installed,
so YMMV with it. It may require some massaging to work on your system. It's really just
an example of how to do various things in one place.

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
