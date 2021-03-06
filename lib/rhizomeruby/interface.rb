# Copyright (c) 2017 Chris Seaton
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module Rhizome
  
  # Manages calls into native code, and back into Ruby. The extra
  # responsibility over just doing the call is also in marshalling the
  # arguments in and the return value out.
  
  class Interface
    
    attr_reader :call_managed_address
    attr_reader :continue_in_interpreter_address
    attr_reader :symbols
  
    def initialize(handles)
      @handles = handles
      @call_managed_function = Memory.from_proc(:long, [:long, :long], &method(:call_managed))
      @call_managed_address = @call_managed_function.to_i
      @continue_in_interpreter_function = Memory.from_proc(:long, [:long, :long, :long], &method(:continue_in_interpreter))
      @continue_in_interpreter_address = @continue_in_interpreter_function.to_i
      @symbols = {
          @call_managed_address => :call_managed,
          @continue_in_interpreter_address => :continue_in_interpreter
      }
    end
    
    # Call a native function (passed in as a proc).
    
    def call_native(function, *args)
      args = *args.map { |a| @handles.to_native(a) }
      ret = function.call(*args)
      @handles.from_native(ret)
    end
    
    private
    
    # Call a managed function (called from native).
    
    def call_managed(args_pointer, args_count)
      # Read the receiver, method name, and then the args from the buffer
      buffer = Memory.new((args_count + 2) * Config::WORD_BYTES, args_pointer)
      handles = buffer.read_words(0, args_count + 2)
      
      # Convert argument handles to objects
      receiver, name, *args = handles.map { |h| @handles.from_native(h) }
      
      # Make the call
      ret = receiver.send(name, *args)
      
      # Convert the return object to a handle
      @handles.to_native(ret)
    end

    # Continue in the interpreter (called from native).

    def continue_in_interpreter(frame_pointer, stack_pointer, deopt_map_handle)
      # Get the frame as a list of values.

      frame_size = frame_pointer - stack_pointer
      frame_memory = Memory.new(frame_size, stack_pointer)
      frame_words = frame_memory.read_words(0, frame_size / Config::WORD_BYTES)

      # Get the deoptimisation map as a Ruby object.

      deopt_map = @handles.from_native(deopt_map_handle)

      # Read off the stack.

      stack = []

      deopt_map.stack.size.times do
        stack.unshift @handles.from_native(frame_words.shift)
      end

      # Read off the arguments. Note that if the arguments have been used at this
      # point in the program then registers that they were using we may have
      # been re-allocated to store a different value, which is what we're now
      # reading instead of the argument. However that only happens if we're beyond
      # the point where we need the arguments, so it shouldn't matter.

      args = []

      deopt_map.args.size.times do
        args.unshift @handles.from_native(frame_words.shift)
      end

      # Read off the receiver.

      receiver = @handles.from_native(frame_words.shift)

      # Here we would read off the values of local variables, but in our examples
      # we don't have any to exercise this so we haven't implemented it.

      locals = {}

      # A hook method allows you to see the how we will continue in the interpreter.

      send :before_continue, deopt_map, receiver, args, stack, locals if respond_to?(:before_continue)

      # Continue in the interpreter!

      interpreter = Interpreter.new
      value = interpreter.interpret(deopt_map.insns, receiver, args, nil, deopt_map.ip, stack, locals)

      @handles.to_native(value)
    end
    
  end
  
end
