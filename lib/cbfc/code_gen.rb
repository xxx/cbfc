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
      Ast::MultiplyLoop => :multiply_loop,
      Ast::ZeroCell => :zero_cell,
      Ast::Loop => :do_loop
    }.freeze

    NATIVE_ZERO = LLVM::Int(0)
    NATIVE_BITS = FFI.type_size(:int) * 8

    # Reverses the contents of a String or IO object.
    #
    # @param ast [Cbfc::Ast::Program] the AST of the program to compile
    # @param target_triple [String] The target triple of the executable. Can typically be
    #   found via `gcc -dumpmachine` or `llvm-config --host-target`. Some massaging may
    #   be required to get it exactly right. Defaults to 'x86_64-linux-gnu'
    # @param cell_count: Number of cells in the memory array. Defaults to 30,000.
    # @param cell_width: Width (in bits) of each cell in the memory array.
    #   8, 16, 32, 64, and 128 are valid values. Any other value results in native ints.
    #   Defaults to native ints.
    # @param enable_memory_wrap: Whether or not we check for whether the pointer needs to
    #   wrap around when it changes. Setting this to false significantly speeds up
    #   execution of programs, but can also result in segfaults or undefined behavior
    #   if the program is liberal with where it tries to access memory. When this is
    #   set to false, the pointer is started in the middle of the memory array, rather
    #   than at the traditional 0 index, to help avoid segfaults.
    #   Defaults to true.
    # @return [Cbfc::CodeGen] a new CodeGen instance
    def initialize(
      ast,
      target_triple: 'x86_64-linux-gnu',
      cell_count: CELL_COUNT,
      cell_width: :native,
      enable_memory_wrap: true
    )
      @ast = ast
      @module = LLVM::Module.new('cbf')

      @module.triple = target_triple
      @cell_count = cell_count
      @enable_memory_wrap = enable_memory_wrap

      @putchar = @module.functions.add('putchar', [LLVM::Int], LLVM::Int) do |function, _int|
        function.add_attribute :no_unwind_attribute
      end

      @getchar = @module.functions.add('getchar', [], LLVM::Int) do |function|
        function.add_attribute :no_unwind_attribute
      end

      @ptr = @module.globals.add(LLVM::Int, :ptr) do |var|
        # if disabling memory wrap, start ptr in the middle to reduce chances
        # of illegal accesses or undefined behavior.
        var.initializer = @enable_memory_wrap ? NATIVE_ZERO : LLVM::Int(cell_count / 2)
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

    def compile(node = @ast, builder = nil)
      method = DISPATCH_TABLE.fetch(node.class)
      send(method, node, builder)
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

    def program(node, _builder = nil)
      @main = @module.functions.add('main', [], LLVM::Int) do |function|
        @current_function = function
        entry = function.basic_blocks.append('entry')

        entry.build do |b|
          b.store NATIVE_ZERO, @ptr

          node.ops.each { |op_node| compile(op_node, b) }

          b.ret NATIVE_ZERO
        end
      end
    end

    def inc_ptr(node, b)
      b.store offset_ptr(b, offset: node.count), @ptr
    end

    def dec_ptr(node, b)
      b.store offset_ptr(b, offset: -node.count), @ptr
    end

    def inc_val(node, b)
      addr = current_cell(b)
      value = b.load addr, 'inc_val_load'
      b.store b.add(value, @int_type.from_i(node.count), 'inc_val_add'), addr
    end

    def dec_val(node, b)
      addr = current_cell(b)
      value = b.load addr, 'dec_val_load'
      b.store b.sub(value, @int_type.from_i(node.count), 'dec_val_sub'), addr
    end

    def write_byte(_node, b)
      value = b.load current_cell(b), 'write_byte_load'

      if @cell_width < NATIVE_BITS
        value = b.sext(value, LLVM::Int)
      elsif @cell_width > NATIVE_BITS
        value = b.trunc(value, LLVM::Int)
      end

      b.call @putchar, value
    end

    def read_byte(_node, b)
      value = b.call(@getchar)

      if @cell_width < NATIVE_BITS
        value = b.trunc(value, @int_type)
      elsif @cell_width > NATIVE_BITS
        value = b.sext(value, @int_type)
      end

      b.store value, current_cell(b)
    end

    def multiply_loop(node, b)
      current_value = b.load current_cell(b), 'multiply_loop_ptr_load'

      node.offsets.each do |pair|
        offset, multiplier = pair
        offset_addr = current_cell(b, offset: offset)
        offset_value = b.load offset_addr, 'multiply_loop_cell_load'
        if multiplier > 1
          multiplied = b.mul current_value, @int_type.from_i(multiplier), 'multiply_loop_mul'
          b.store b.add(offset_value, multiplied, 'multiply_loop_cell_add'), offset_addr
        else
          b.store b.add(offset_value, current_value, 'multiply_loop_cell_add'), offset_addr
        end
      end

      b.store @width_zero, current_cell(b)
    end

    def zero_cell(_node, b)
      b.store @width_zero, current_cell(b)
    end

    def do_loop(node, b)
      loop_head = @current_function.basic_blocks.append('loop_head')
      loop_body = @current_function.basic_blocks.append('loop_body')
      loop_end = @current_function.basic_blocks.append('loop_end')

      b.br loop_head

      loop_head.build do |builder|
        loop_cond = builder.icmp :eq,
                                 builder.load(current_cell(builder), 'load_for_icmp'),
                                 @width_zero,
                                 'loop_head_cond'
        builder.cond loop_cond, loop_end, loop_body
      end

      loop_body.build do |builder|
        node.ops.each { |op_node| compile(op_node, builder) }

        builder.br loop_head
      end

      b.position_at_end(loop_end)
    end

    def offset_ptr(b, offset: 0)
      current = b.load(@ptr, 'offset_ptr_load')
      return current if offset.zero?

      current = b.add(current, LLVM::Int(offset), 'offset_ptr_add')

      # skip all of this if we're not caring about wrapping memory
      return current unless @enable_memory_wrap

      # handle memory wrapping
      if_greater_body = @current_function.basic_blocks.append('if_greater_body')
      if_less_head = @current_function.basic_blocks.append('if_less_head')
      if_less_body = @current_function.basic_blocks.append('if_less_body')
      if_end = @current_function.basic_blocks.append('if_end')

      if_greater = b.icmp :sge,
                          current,
                          LLVM::Int(@cell_count),
                          'offset_ptr_sge'
      b.cond if_greater, if_greater_body, if_less_head

      sub = nil
      add = nil
      if_greater_body.build do |builder|
        sub = builder.sub current, LLVM::Int(@cell_count)
        builder.br if_end
      end

      if_less_head.build do |builder|
        if_less = builder.icmp :slt,
                               current,
                               NATIVE_ZERO,
                               'offset_ptr_slt'
        builder.cond if_less, if_less_body, if_end
      end

      if_less_body.build do |builder|
        add = builder.add current, LLVM::Int(@cell_count)
        builder.br if_end
      end

      result = nil
      if_end.build do |builder|
        result = builder.phi(
          LLVM::Int,
          { if_greater_body => sub, if_less_body => add, if_less_head => current },
          'offset_ptr_phi'
        )
      end

      b.position_at_end(if_end)

      result
    end

    def current_cell(b, offset: 0)
      current_index = offset_ptr(b, offset: offset)

      b.gep(@memory, [LLVM::Int(0), current_index], 'current_cell')
    end
  end
end
