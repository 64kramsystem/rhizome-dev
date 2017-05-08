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

require 'rubyjit'

describe RubyJIT::Backend::AMD64::Disassembler do

  before :each do
    @assembler = RubyJIT::Backend::AMD64::Assembler.new

    @disassemble = proc {
      @disassembler = RubyJIT::Backend::AMD64::Disassembler.new(@assembler.bytes)
    }
  end

  describe '#read' do

    describe 'correctly disassembles' do

      describe 'push' do

        it 'with low registers' do
          @assembler.push RubyJIT::Backend::AMD64::RBP
          @disassemble.call
          expect(@disassembler.next).to eql '0x0000000000000000  push %rbp            ; 0x55        '
        end

        it 'with high registers' do
          @assembler.push RubyJIT::Backend::AMD64::R15
          @disassemble.call
          expect(@disassembler.next).to eql '0x0000000000000000  push %r15            ; 0x4157      '
        end

      end

      describe 'pop' do

        it 'with low registers' do
          @assembler.pop RubyJIT::Backend::AMD64::RBP
          @disassemble.call
          expect(@disassembler.next).to eql '0x0000000000000000  pop %rbp             ; 0x5d        '
        end

        it 'with high registers' do
          @assembler.pop RubyJIT::Backend::AMD64::R15
          @disassemble.call
          expect(@disassembler.next).to eql '0x0000000000000000  pop %r15             ; 0x415f      '
        end

      end

      describe 'mov' do

        it 'register to register' do
          @assembler.mov RubyJIT::Backend::AMD64::RSP, RubyJIT::Backend::AMD64::RBP
          @disassemble.call
          expect(@disassembler.next).to eql '0x0000000000000000  mov %rsp %rbp        ; 0x4889e5    '
        end

        it 'address to register' do
          @assembler.mov RubyJIT::Backend::AMD64::RSP + 10, RubyJIT::Backend::AMD64::RBP
          @disassemble.call
          expect(@disassembler.next).to eql '0x0000000000000000  mov %rsp+10 %rbp     ; 0x488b6c0a  '
        end

        it 'register to address' do
          @assembler.mov RubyJIT::Backend::AMD64::RSP, RubyJIT::Backend::AMD64::RBP + 10
          @disassemble.call
          expect(@disassembler.next).to eql '0x0000000000000000  mov %rsp %rbp+10     ; 0x4889650a  '
        end

        it 'with negative offsets' do
          @assembler.mov RubyJIT::Backend::AMD64::RSP, RubyJIT::Backend::AMD64::RBP - 10
          @disassemble.call
          expect(@disassembler.next).to eql '0x0000000000000000  mov %rsp %rbp-10     ; 0x488965f6  '
        end

      end

      describe 'add' do

        it 'register to register' do
          @assembler.add RubyJIT::Backend::AMD64::RSP, RubyJIT::Backend::AMD64::RBP
          @disassemble.call
          expect(@disassembler.next).to eql '0x0000000000000000  add %rsp %rbp        ; 0x4801e5    '
        end

      end

      it 'ret' do
        @assembler.ret
        @disassemble.call
        expect(@disassembler.next).to eql '0x0000000000000000  ret                  ; 0xc3        '
      end

      it 'unknown data' do
        @assembler.send :emit, 0x00
        @disassemble.call
        expect(@disassembler.next).to eql '0x0000000000000000  data 0x00            ; 0x00        '
      end

    end

  end

end
