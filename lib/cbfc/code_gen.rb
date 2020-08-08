# frozen_string_literal: true

# much inspiration for this class' code taken from
# https://github.com/chriswailes/RLTK/blob/master/examples/brainfuck/bfjit.rb

module Cbfc
  class CodeGen
    extend Forwardable
    def_delegators :@module, :to_s

    CELL_COUNT = 30_000

    DISPATCH_TABLE = {
      Ast::Program => :program,
      Ast::IncPtr => :inc_ptr,
      Ast::DecPtr => :dec_ptr,
      Ast::IncVal => :inc_val,
      Ast::DecVal => :dec_val,
      Ast::WriteByte => :write_byte,
      Ast::ReadByte => :read_byte,
      Ast::ZeroCell => :zero_cell,
      Ast::Loop => :do_loop
    }.freeze

    NATIVE_ZERO = LLVM::Int(0)
    NATIVE_BITS = FFI.type_size(:int) * 8

    def initialize(ast, target_triple: 'x86_64-linux-gnu', cell_count: CELL_COUNT, cell_width: :native)
      @ast = ast
      @module = LLVM::Module.new('cbf')

      @module.triple = target_triple

      @putchar = @module.functions.add('putchar', [LLVM::Int], LLVM::Int) do |function, _int|
        function.add_attribute :no_unwind_attribute
      end

      @getchar = @module.functions.add('getchar', [], LLVM::Int) do |function|
        function.add_attribute :no_unwind_attribute
      end

      @ptr = @module.globals.add(LLVM::Int, :ptr) do |var|
        var.initializer = NATIVE_ZERO
        var.linkage = :internal
      end

      case cell_width
      when 8, 16, 32, 64, 128
        @cell_width = cell_width
        @int_type = Object.const_get("LLVM::Int#{cell_width}")
      else
        # default to native
        @cell_width = NATIVE_BITS
        @int_type = LLVM::Int
      end

      @width_zero = @int_type.from_i(0)

      @memory = @module.globals.add(LLVM::Type.array(@int_type, cell_count), :memory) do |var|
        # var.initializer = LLVM::ConstantAggregateZero.get(LLVM::Int)
        var.initializer = LLVM::ConstantArray.const(@int_type, cell_count) { @width_zero }
        var.linkage = :internal
      end
    end

    def compile(node = @ast, builder = nil, function = nil)
      method = DISPATCH_TABLE.fetch(node.class)
      send(method, node, builder, function)
      self
    end

    def to_bitcode(path)
      @module.write_bitcode(path)
    end

    def to_file(path)
      File.write(path, to_s)
    end

    def interpret_jit
      LLVM.init_jit

      engine = LLVM::JITCompiler.new(@module)
      engine.run_function(@main)
      engine.dispose
    end

    private

    def program(node, _builder = nil, _function = nil)
      @main = @module.functions.add('main', [], LLVM::Int) do |function|
        entry = function.basic_blocks.append('entry')

        entry.build do |b|
          b.store NATIVE_ZERO, @ptr

          node.ops.each { |op_node| compile(op_node, b, function) }

          b.ret NATIVE_ZERO
        end
      end
    end

    def inc_ptr(node, b, _function)
      b.store b.add(b.load(@ptr, 'inc_ptr_load'), LLVM::Int(node.count), 'inc_ptr_add'), @ptr
    end

    def dec_ptr(node, b, _function)
      b.store b.sub(b.load(@ptr, 'dec_ptr_load'), LLVM::Int(node.count), 'dec_ptr_sub'), @ptr
    end

    def inc_val(node, b, _function)
      addr = current_cell(b)
      value = b.load addr, 'inc_val_load'
      b.store b.add(value, @int_type.from_i(node.count), 'inc_val_add'), addr
    end

    def dec_val(node, b, _function)
      addr = current_cell(b)
      value = b.load addr, 'dec_val_load'
      b.store b.sub(value, @int_type.from_i(node.count), 'dec_val_sub'), addr
    end

    def write_byte(_node, b, _function)
      value = b.load current_cell(b), 'write_byte_load'

      if @cell_width < NATIVE_BITS
        value = b.zext(value, LLVM::Int)
      elsif @cell_width > NATIVE_BITS
        value = b.trunc(value, LLVM::Int)
      end

      b.call @putchar, value
    end

    def read_byte(_node, b, _function)
      value = b.call(@getchar)

      if @cell_width < NATIVE_BITS
        value = b.trunc(value, @int_type)
      elsif @cell_width > NATIVE_BITS
        value = b.zext(value, @int_type)
      end

      b.store value, current_cell(b)
    end

    def zero_cell(_node, b, _function)
      b.store @width_zero, current_cell(b)
    end

    def do_loop(node, b, function)
      loop_head = function.basic_blocks.append('loop_head')
      loop_body = function.basic_blocks.append('loop_body')
      loop_end = function.basic_blocks.append('loop_end')

      b.br loop_head

      loop_head.build do |builder|
        loop_cond = builder.icmp :eq,
                                 builder.load(current_cell(builder), 'load_for_icmp'),
                                 @width_zero,
                                 'loop_head_cond'
        builder.cond loop_cond, loop_end, loop_body
      end

      loop_body.build do |builder|
        node.ops.each { |op_node| compile(op_node, builder, function) }

        builder.br loop_head
      end

      b.position_at_end(loop_end)
    end

    def current_cell(b, offset: 0)
      value = offset.positive? ? b.add(@ptr, LLVM::Int(offset)) : @ptr

      b.gep(@memory, [LLVM::Int(0), b.load(value, 'current_cell_ptr')], 'current_cell')
    end
  end
end
