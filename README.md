# nimgraphviz

The `nimgraphviz` module is a library for making graphs using
[GraphViz](http://www.graphviz.org) based on
[PyGraphviz](http://pygraphviz.github.io).

To use it, add
```
requires "nimgraphviz >= 0.1.0"
```
to your `.nimble` file

To export images, you must have GraphViz installed. Download it here:
[https://graphviz.gitlab.io/download](https://graphviz.gitlab.io/download)

Here is an example of creating a simple graph:

```nim
# create a directed graph
var graph = initGraph(directed=true)

# set some attributes of the graph:
graph.graphAttr.add("fontsize", "32")
graph.graphAttr.add("label", "Test Graph")

# add edges:
# (if a node does not exist already it will be created automatically)
graph.addEdge("a", "b", "a-to-b", [("label", "A to B")])
graph.addEdge("c", "b", "c-to-b", [("style", "dotted")])
graph.addEdge("b", "a", "b-to-a")
graph.addNode("c", [("color", "blue"), ("shape", "box"),
                        ("style", "filled"), ("fontcolor", "white")])
graph.addNode("d", [("lable", "node")])

# if you want to export the graph in the DOT language,
# you can do it like this:
# echo graph.exportDot()

# Export graph as PNG:
graph.exportImage("test_graph.png")
```
