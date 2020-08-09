# frozen_string_literal: true

module Cbfc
  class CCodeGen
    CELL_COUNT = LlvmCodeGen::CELL_COUNT
    DISPATCH_TABLE = LlvmCodeGen::DISPATCH_TABLE

    attr_reader :io

    def initialize(
      ast,
      io,
      cell_count: CELL_COUNT,
      cell_width: :native,
      enable_memory_wrap: true
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
        @cell_width = LlvmCodeGen::NATIVE_BITS
        @int_type = 'int'
      end
      @enable_memory_wrap = enable_memory_wrap
      @indent_level = 1
    end

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
                     <<~STRING
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
                     STRING
                   else
                     <<~STRING
                       inline int offset_ptr(int offset) {
                           return ptr + offset;
                       }
                     STRING
                   end

      filename = @io.respond_to?(:path) ? File.basename(@io.path, '.*') : 'myfile'

      @io.puts <<~STRING.chomp
        /*
         * translated with cbfc - https://github.com/xxx/cbfc
         *
         * compile with something like "gcc #{filename}.c -o #{filename} -O3"
         */

        #include <stdio.h>
        #include <stdint.h>

        #define CELL_COUNT #{@cell_count}

        int ptr = 0;
        #{@int_type} memory[CELL_COUNT] = {0};

        #{offset_ptr}

        int main() {
      STRING
    end

    def write_footer
      @io.puts <<~STRING.chomp
            return 0;
        }
      STRING
    end

    def emit_indented(str)
      @io.puts "#{'    ' * @indent_level}#{str}"
    end
  end
end
