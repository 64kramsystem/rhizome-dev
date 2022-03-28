#!/usr/bin/env ruby

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

# Demonstrates calling into native code and back into Ruby.

require_relative '../lib/rhizomeruby'
require_relative '../spec/rhizomeruby/fixtures'

raise 'this experiment only works on AMD64' unless Rhizome::Config::AMD64

handles = Rhizome::Handles.new(Rhizome::Config::WORD_BITS)
interface = Rhizome::Interface.new(handles)

c = interface.call_managed_address

puts "To call from native to manged, call 0x#{c.to_s(16)} with a pointer and a number of args"

s = handles.to_native(:+)

if Rhizome::Config::AMD64
  machine_code = [
    0x56,                   # push rsi      push the argument
    0x48, 0xb8, *[s].pack('Q<').bytes,
                            # mov ... rax   rax = the method name handle
    0x50,                   # push rax      push the method name handle
    0x57,                   # push rdi      push the receiver
    0x48, 0x89, 0xe7,       # mov rsp rdi   rdi = the address of last value we pushed
    0x48, 0xc7, 0xc6, *[1].pack('L<').bytes,
                            # mov 1 rsi     rsi = the number of arguments
    0x48, 0xb8, *[c].pack('Q<').bytes,
                            # mov ... rax   rax = the address of the call to managed
    0xff, 0xd0,             # call *rax     call to managed
    0x5b,                   # pop rbx       pop the receiver
    0x5b,                   # pop rbx       pop the method name handle
    0x5b,                   # pop rbx       pop the argument
    0xc3                    # return
  ]
else
  raise 'no machine code sample for this architecture'
end

memory = Rhizome::Memory.new(machine_code.size)
memory.write 0, machine_code
memory.executable = true
native_method = memory.to_proc([:long, :long], :long)

puts 'calling it to perform a Ruby send'

puts interface.call_native(native_method, 14, 2)
