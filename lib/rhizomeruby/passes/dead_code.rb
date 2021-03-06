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

require 'set'

module Rhizome
  module Passes

    # An optimisation pass to remove dead code.

    class DeadCode

      def run(graph)
        modified = false

        # Look at each node.

        graph.all_nodes.each do |n|
          # If the node has no users (no outputs) then it is dead - it's as simple
          # as that. We have encoded side effects as a special kind of output, so
          # we need no special logic so that we don't remove side effects. The only
          # special case is for the finish node, which of course always has no users.

          if n.outputs.empty? && n.op != :finish
            n.remove
            modified = true
            next
          end

          # If a node has no users, except for control flow, and it has no side
          # effects, then it is dead, but we need to keep the control flow path
          # through it. We sometimes get nodes like this hanging around after other
          # transformations.

          if n.outputs.edges.all?(&:control?) && !n.has_side_effects?
            n.inputs.from_nodes.each do |a|
              n.outputs.edges.each do |b|
                if b.control? && !a.outputs.with_output_name(:control).to_nodes.include?(b.to)
                  a.output_to :control, b.to
                end
              end
            end

            n.remove
            modified = true
            next
          end
        end

        modified
      end

    end

  end
end
