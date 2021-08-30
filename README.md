# nimgraphviz

The `nimgraphviz` module is a library for making graphs using
[GraphViz](http://www.graphviz.org) based on
[PyGraphviz](http://pygraphviz.github.io).

To use it, add
```
requires "nimgraphviz >= 0.2.0"
```
to your `.nimble` file.

To export images, you must have GraphViz installed. Download it here:
[https://graphviz.gitlab.io/download](https://graphviz.gitlab.io/download).

Read the docs [here](https://quinnfreedman.github.io/nimgraphviz/).

Here is an example of creating a simple graph:

```nim
let main = newGraph() # create a graph (strict, but not oriented)
let sub = newSubGraph(main) # the graph can have subgraph
# the subgraph can have subgraphs too!

# adding an edge, along with attributes
main.addEdge("a"--"b", ("label", "A to B"))

# attributes can also be added afterwards
sub.addEdge("b"--"c")
sub["b"--"c"]["style"] = "dotted"

# similar features are available for nodes
main["d"]["label"] = "This node stands alone"

# subgraphs whose name begin in "cluster" have a special meaning in DOT.
sub.name = "cluster_whatever"
sub["bgcolor"] = "grey" # hey, graph attributes can be set as well!

# if you want to export the graph in the DOT language,
# you can do it like this:
echo main.exportDot()

# Export graph as PNG:
graph.exportImage("test_graph.png")
```
