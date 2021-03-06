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

require 'rhizomeruby'

describe Rhizome::IR::Graph do

  describe '.new' do

    it 'creates a graph with start and finish nodes' do
      graph = Rhizome::IR::Graph.new
      expect(graph.start).to be_a(Rhizome::IR::Node)
      expect(graph.finish).to be_a(Rhizome::IR::Node)
    end

  end

  describe '.from_fragment' do

    it 'creates a graph from a builder fragment' do
      merge = Rhizome::IR::Node.new(:merge)
      fragment = Rhizome::IR::Builder::GraphFragment.new({}, [], merge, merge, merge, {}, [])
      graph = Rhizome::IR::Graph.from_fragment(fragment)
      expect(graph.contains? { |node| node.op == :merge }).to be_truthy
    end

  end

  before :each do
    @add_graph = Rhizome::IR::Graph.new
    a_node = Rhizome::IR::Node.new(:constant, value: 14)
    b_node = Rhizome::IR::Node.new(:arg, n: 0)
    send_node = Rhizome::IR::Node.new(:send, name: :+)
    a_node.output_to :value, send_node, :receiver
    b_node.output_to :value, send_node, :args
    @add_graph.start.output_to :control, send_node
    send_node.output_to :control, @add_graph.finish
    send_node.output_to :value, @add_graph.finish
  end

  describe '#visit_nodes' do

    it 'visits each node once' do
      nodes = []
      @add_graph.visit_nodes do |node|
        nodes.push node.op
      end
      expect(nodes).to contain_exactly :start, :finish, :constant, :arg, :send
    end

  end

  describe '#all_nodes' do

    it 'returns an array of all nodes' do
      expect(@add_graph.all_nodes.map(&:op)).to contain_exactly :start, :finish, :constant, :arg, :send
    end

  end

  describe '#find_node' do

    it 'can be used to find a single node' do
      found = @add_graph.find_node do |node|
        node.op == :constant
      end
      expect(found).to_not be_nil
      expect(found.op).to eql :constant
    end

    it 'returns nil if no node is found' do
      found = @add_graph.find_node do |node|
        node.op == :does_not_exist
      end
      expect(found).to be_nil
    end

    it 'takes an optional op filter' do
      found = @add_graph.find_node(:constant) do |node|
        node.props[:value] == 14
      end
      expect(found).to_not be_nil
      expect(found.op).to eql :constant
    end

  end

  describe '#find_nodes' do

    it 'can be used to find a single node' do
      found = @add_graph.find_nodes do |node|
        node.op == :constant
      end
      expect(found.size).to eql 1
      expect(found.first.op).to eql :constant
    end

    it 'returns an empty array if no node is found' do
      found = @add_graph.find_nodes do |node|
        node.op == :does_not_exist
      end
      expect(found).to be_empty
    end

    it 'takes an optional op filter' do
      found = @add_graph.find_nodes(:constant) do |node|
        node.props[:value] == 14
      end
      expect(found.size).to eql 1
      expect(found.first.op).to eql :constant
    end

  end

  describe '#size' do

    it 'returns the number of nodes in the graph' do
      expect(@add_graph.size).to eql 5
    end

  end

end
