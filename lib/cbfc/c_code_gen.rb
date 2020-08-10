# frozen_string_literal: true

module Cbfc
  class CCodeGen
    CELL_COUNT = CodeGen::CELL_COUNT
    DISPATCH_TABLE = CodeGen::DISPATCH_TABLE

    attr_reader :io

    # Create a code generator targeting the C (C99) programming language.
    #
    # @param ast [Cbfc::Ast::Program] the AST of the program to compile
    # @param io [IO] An IO object to write to. File is most common probably, but
    #   e.g. StringIO also can be used.
    # @param cell_count: Number of cells in the memory array. Defaults to 30,000.
    # @param cell_width: Width (in bits) of each cell in the memory array.
    #   8, 16, 32, and 64 are valid values. Any other value results in native ints.
    #   Defaults to 8-bit cells.
    # @param enable_memory_wrap: Whether or not we check for whether the pointer needs to
    #   wrap around when it changes. Setting this to false significantly speeds up
    #   execution of programs, but can also result in segfaults when compiled with
    #   optimizations. (Looking at you, Mandelbrot)
    #   Defaults to false.
    # @return [Cbfc::CCodeGen] a new CCodeGen instance
    def initialize(
      ast,
      io,
      cell_count: CELL_COUNT,
      cell_width: 8,
      enable_memory_wrap: false
    )
      @ast = ast
      @io = io
      @cell_count = cell_count
      case cell_width
      when 8, 16, 32, 64
        @cell_width = cell_width
        @int_type = "int#{cell_width}_t"
      else
        # default to native
        @cell_width = CodeGen::NATIVE_BITS
        @int_type = 'int'
      end
      @enable_memory_wrap = enable_memory_wrap
      @indent_level = 1
    end

    # Compile a node and write the output to @io
    #
    # @param node [Cbfc::Ast::BfNode] An AST node to compile
    def compile(node = @ast)
      method = DISPATCH_TABLE.fetch(node.class)
      send(method, node)
      self
    end

    private

    def program(node)
      write_preamble
      node.ops.each { |op_node| compile(op_node) }
      write_footer
    end

    def inc_ptr(node)
      emit_indented "ptr = offset_ptr(#{node.count});"
    end

    def dec_ptr(node)
      emit_indented "ptr = offset_ptr(-#{node.count});"
    end

    def inc_val(node)
      emit_indented "memory[ptr] += #{node.count};"
    end

    def dec_val(node)
      emit_indented "memory[ptr] -= #{node.count};"
    end

    def write_byte(_node)
      emit_indented 'putchar(memory[ptr]);'
    end

    def read_byte(_node)
      emit_indented 'memory[ptr] = getchar();'
    end

    def multiply_loop(node)
      node.offsets.each do |offset, multiplier|
        emit_indented("memory[offset_ptr(#{offset})] += (#{@int_type})(memory[ptr] * #{multiplier});")
      end

      emit_indented('memory[ptr] = 0;')
    end

    def scan_left(_node)
      unless @cell_width == 8
        do_loop(Ast::Loop.new([Ast::DecPtr.new(1)]))
        return
      end

      emit_indented('ptr -= (long)((void *)(memory + ptr) - memrchr(memory, 0, ptr + 1));')
    end

    def scan_right(_node)
      unless @cell_width == 8
        do_loop(Ast::Loop.new([Ast::IncPtr.new(1)]))
        return
      end

      emit_indented('ptr += (long)(memchr(memory + ptr, 0, sizeof(memory)) - (void *)(memory + ptr));')
    end

    def zero_cell(_node)
      emit_indented('memory[ptr] = 0;')
    end

    def do_loop(node)
      @io.puts
      emit_indented 'while(memory[ptr] != 0) {'
      @indent_level += 1

      node.ops.each { |op_node| compile(op_node) }

      @indent_level -= 1
      emit_indented '}'
      @io.puts
    end

    def write_preamble
      offset_ptr = if @enable_memory_wrap
                     <<~CODE
                       int offset_ptr(int offset) {
                           if (offset == 0) {
                               return ptr;
                           }

                           int new_offset = ptr + offset;
                           if (new_offset >= CELL_COUNT) {
                               new_offset -= CELL_COUNT;
                           } else if (new_offset < 0) {
                               new_offset += CELL_COUNT;
                           }
                           return new_offset;
                       }
                     CODE
                   else
                     <<~CODE
                       int offset_ptr(int offset) {
                           return ptr + offset;
                       }
                     CODE
                   end

      filename = @io.respond_to?(:path) ? File.basename(@io.path, '.*') : 'myfile'

      memrchr = if Cbfc::MemrchrChecker::HAS_MEMRCHR
                  ''
                else
                  <<~CODE
                    /* implementation taken from https://barnowl.mit.edu/browser/compat/memrchr.c */
                    void *memrchr(const void *s, int c, size_t n) {
                        int i;
                        const unsigned char *ss = s;
                        for (i = n-1; i >= 0; i--) {
                            if (ss[i] == (unsigned char)c)
                                return ss + i;
                        }
                        return NULL;
                    }
                  CODE
                end

      @io.puts <<~CODE.chomp
        /*
         * translated with cbfc - https://github.com/xxx/cbfc
         *
         * compile with something like "gcc #{filename}.c -o #{filename} -O3"
         */

        #{Cbfc::MemrchrChecker::HAS_MEMRCHR && '#define _GNU_SOURCE'}
        #include <stdio.h>
        #include <stdint.h>
        #include <string.h>

        #define CELL_COUNT #{@cell_count}

        int ptr = 0;
        #{@int_type} memory[CELL_COUNT] = {0};

        #{memrchr}
        #{offset_ptr}

        int main() {
      CODE
    end

    def write_footer
      @io.puts <<~CODE.chomp
            return 0;
        }
      CODE
    end

    def emit_indented(str)
      @io.puts "#{'    ' * @indent_level}#{str}"
    end
  end
end
