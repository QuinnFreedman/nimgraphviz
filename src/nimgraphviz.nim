# nimgraphviz
# Copyright Quinn, Aveheuzed
# Nim bindings for the GraphViz tool and the DOT graph language

## The `nimgraphviz` module is a library for making graphs using
## `GraphViz <http://www.graphviz.org>`_ based on
## `PyGraphviz <http://pygraphviz.github.io>`_.
##
## To export images, you must have GraphViz installed. Download it here:
## `https://graphviz.gitlab.io/download <https://graphviz.gitlab.io/download>`_
##
## Here is an example of creating a simple graph:
##
## .. code-block:: nim
##    # create a directed graph
##    let graph = newDiGraph()
##
##    # set some attributes of the graph:
##    graph["fontsize"] = "32"
##    graph["label"] = "Test Graph"
##    # (You can also access nodes and edges attributes this way :)
##    # graph["a"]["bgcolor"] = "red"
##    # graph["a"->"b"]["arrowhead"] = "diamond"
##
##    # add edges:
##    # (if a node does not exist already it will be created automatically)
##    graph.addEdge("a"->"b" ("label", "A to B"))
##    graph.addEdge("c"->"b", ("style", "dotted"))
##    graph.addEdge("b"->"a")
##    graph.addNode("c", ("color", "blue"), ("shape", "box"),
##                        ("style", "filled"), ("fontcolor", "white"))
##    graph.addNode("d", ("label", "node 'd'"))
##
##    # if you want to export the graph in the DOT language,
##    # you can do it like this:
##    # echo graph.exportDot()
##
##    # Export graph as PNG:
##    graph.exportImage("test_graph.png")
##
##    You can also nest subgraphs indefinitely :
##    let sub = newSubGraph(graph)
##    # let subsub = newSubGraph(sub)
##    sub.addEdge("x"->"y")
##    # The subgraph is automatically included in the main graph
##    # when you export it. It can also work standalone.

include "nimgraphviz/private/edges", "nimgraphviz/private/graphs"


when isMainModule :
  let main = newGraph()
  let sub = newSubGraph(main)

  main.addEdge("a"--"b")
  sub.addEdge("b"--"c")
  sub.name = "cluster_whatever"

  echo main.exportDot()
