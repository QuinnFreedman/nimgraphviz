# nimgraphviz
# Copyright Quinn
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
##    var graph = newGraph(directed=true)
##
##    # set some attributes of the graph:
##    graph.graphAttr.add("fontsize", "32")
##    graph.graphAttr.add("label", "Test Graph")
##
##    # add edges:
##    # (if a node does not exist already it will be created automatically)
##    graph.addEdge("a", "b", "a-to-b", [("label", "A to B")])
##    graph.addEdge("c", "b", "c-to-b", [("style", "dotted")])
##    graph.addEdge("b", "a", "b-to-a")
##    graph.addNode("c", [("color", "blue"), ("shape", "box"),
##                        ("style", "filled"), ("fontcolor", "white")])
##    graph.addNode("d", [("lable", "node")])
##
##    # if you want to export the graph in the DOT language,
##    # you can do it like this:
##    # echo graph.exportDot()
##
##    # Export graph as PNG:
##    graph.exportImage("test_graph.png")

import
  tables,
  sequtils,
  strutils,
  strformat,
  osproc,
  streams,
  sets,
  shell
export tables

var GV_PATH = ""

proc setGraphVizPath*(path: string) =
  ## sets the directory to search for the GraphViz executable (``dot``)
  ## if it is not in your PATH.
  ## should end in a delimiter ("``/``" or "``\``")
  GV_PATH = path

type GraphVizException = object of Exception

type
  Edge* = tuple
    a, b, key: string

  GraphKind = enum
    gkGraph, gkSubgraph

  Graph* = ref object
    name*: string    ## The name of the graph
    isDirected*: bool  ## Whether or not the graph is directed
    graphAttr*: Table[string, string]  ## A table of key-value pairs
                       ## describing the layout and
                       ## appearence of the graph
    subGraphs: seq[Graph] ## a graph may have multiple sub graphs
    edgesTable: Table[string, HashSet[Edge]]
    edgeAttrs: Table[Edge, Table[string, string]]
    nodeAttrs: Table[string, Table[string, string]]
    case kind: GraphKind
    of gkGraph: discard
    of gkSubgraph:
      id: int
      clusterName*: string

proc newGraph*(name: string = "",
               directed = false,
               kind: GraphKind = gkGraph): Graph =
  result = Graph(
    name: name,
    isDirected: directed,
    graphAttr: initTable[string, string](),
    edgesTable: initTable[string, HashSet[Edge]](),
    edgeAttrs: initTable[Edge, Table[string, string]](),
    nodeAttrs: initTable[string, Table[string, string]](),
    kind: kind
  )

proc initGraph*(name: string = "", directed = false): Graph {.deprecated: "`initGraph` is " &
  " deprecated in favor of `newGraph` as `Graph` is a `ref object`.".} =
  result = newGraph(name, directed)

proc addNode*(self: var Graph, key: string, attrs: openArray[(string, string)])

func sanitize(s: string): string = "\"" & s & "\""

proc newSubgraph*(g: var Graph, name: string): Graph =
  result = newGraph(name = name, directed = true, kind = gkSubgraph)
  result.graphAttr["style"] = "filled"
  result.graphAttr["label"] = name # ""
  result.addNode(name.sanitize, [("style", "plaintext")])
  result.id = g.subGraphs.len
  result.clusterName = "cluster_" & $result.id
  g.subGraphs.add result

proc addGraph*(self: var Graph, g: Graph) =
  ## adds the given graph `g` as a subgraph to `self`
  ## Note: this should not be required if the subgraph was created
  ## using `newSubgraph`!
  self.subGraphs.add g

proc addEdge*(self: var Graph, a, b: string, key: string = "") =
  ## the same as ``addEdge*(self: var Graph, a, b: string, key: string, attrs: openArray[(string, string)])``
  ## but without attributes and ``key`` is optional
  let key = if key.len == 0: &"{a}-to-{b}" else: key
  let edge = (a, b, key)
  if not (a in self.nodeAttrs):
    self.nodeAttrs[a] = initTable[string, string](4)
  if not (b in self.nodeAttrs):
    self.nodeAttrs[b] = initTable[string, string](4)

  if a in self.edgesTable:
    self.edgesTable[a].incl(edge)
  else:
    self.edgesTable[a] = [edge].toSet

  if b in self.edgesTable:
    self.edgesTable[b].incl(edge)
  else:
    self.edgesTable[b] = [edge].toSet


proc addEdge*(self: var Graph, a, b: string, key = "",
        attrs: openArray[(string, string)]) =
  ## Adds an edge to the graph connecting nodes ``a`` and ``b``.
  ## If the nodes don't already exist in the graph, they will be
  ## created
  ##
  ## ``key`` is an identifier for the edge. It can be useful when
  ## you want to have multiple edges between the same two nodes
  ##
  ## ``attrs`` is a set of key-value pairs specifying styling
  ## attributes for the edge. You can call ``addEdge`` again
  ## multiple times with the same nodes and key and different
  ## attrs to add new attributes
  ##
  ## For example:
  ## .. code-block:: nim
  ##   var graph = initGraph()
  ##   graph.addEdge("a", "b", nil, [("color", "blue")])
  ##   graph.addEdge("a", "b", nil, [("style", "dotted")])
  ##
  ## will create a graph with a single dotted, blue edge
  let key = if key.len == 0: &"{a}-to-{b}" else: key
  self.addEdge(a, b, key)

  let edge = (a, b, key)
  if edge in self.edgeAttrs:
    for pair in attrs:
      let (k, v) = pair
      self.edgeAttrs[edge][k] = v
  else:
    self.edgeAttrs[edge] = attrs.toTable()

iterator iterEdges*(self: Graph): Edge =
  ## iterator over all the edges in the graph.
  ## An edge is a three-tuple of two nodes and the edge key
  for key in self.edgesTable.keys:
    for edge in self.edgesTable[key]:
      if edge.a == key:
        yield edge

iterator iterEdges*(self: Graph, nbunch: string): Edge =
  ## iterator over all the edges in the graph that are adjacent
  ## to the given node (coming in or out).
  ## Yields three-tuples of two nodes and the edge key
  if nbunch in self.edgesTable:
    for edge in self.edgesTable[nbunch]:
      yield edge

template seqFromIterImpl[T](iter: untyped) =
  result = newSeq[T]()
  for it in iter:
    result.add(it)

proc edges*(self: Graph): seq[Edge] =
  ## A list of all the edges in the graph
  ## (An edge is a three-tuple of two nodes and the edge key)
  seqFromIterImpl[Edge](self.iterEdges)

proc edges*(self: Graph, nbunch: string): seq[Edge] =
  ## A list of all the edges in the graph that are adjacent to
  ## the given node (coming in or out)
  ## (An edge is a three-tuple of two nodes and the edge key)
  seqFromIterImpl[Edge](self.iterEdges(nbunch))

proc addNode*(self: var Graph, key: string,
        attrs: openArray[(string, string)]) =
  ## Adds a node to the graph.
  ## ``key`` is the name of the node, used to refer to it
  ## when creating edges, etc. It will be used as the label
  ## unless another label is given
  ##
  ## ``attrs`` is a set of key-value pairs describing layout
  ## attributes for the node. You can call ``addNode()`` for
  ## an existing node to update its attributes
  if key in self.nodeAttrs:
    for pair in attrs:
      let (k, v) = pair
      self.nodeAttrs[key][k] = v
  else:
    self.nodeAttrs[key] = attrs.toTable

iterator iterNodes*(self: Graph): string =
  ## Iterates over all of the nodes in the graph
  for node in self.nodeAttrs.keys:
    yield node

proc nodes*(self: Graph): seq[string] =
  ## Returns a ``seq`` of the nodes in the graph
  seqFromIterImpl[string](self.iterNodes)

proc degree*(self: Graph, node: string): int =
  ## The number of edges adjacent to the given node (in or out)
  if node in self.edgesTable:
    self.edgesTable[node].len
  else:
    -1

proc inDegree*(self: Graph, node: string): int =
  ## The number of edges into the given node
  ## If the graph is directed, it is the same as ``degree()``
  if not self.isDirected:
    return self.degree(node)

  if node in self.edgesTable:
    for edge in self.edgesTable[node]:
      if edge.b == node:
        result += 1
  else:
    result = -1

proc outDegree*(self: Graph, node: string): int =
  ## The number of edges out of the given node
  ## If the graph is directed, it is the same as ``degree()``
  if not self.isDirected:
    return self.degree(node)

  if node in self.edgesTable:
    for edge in self.edgesTable[node]:
      if edge.a == node:
        result += 1
  else:
    result = -1

proc attrList(attr: Table[string, string]): seq[string] =
  result = newSeq[string]()
  for pair in attr.pairs:
    let (key, value) = pair
    result.add(&"{key}=\"{value}\"")

proc exportAttrList(attr: Table[string, string]): string =
  let pairs = attrList(attr)
  if pairs.len == 0:
    return ""
  return "[" & pairs.join(", ") & "]"


proc exportAttributes(g: Graph): string =
  result &= "/*\n" &
        " * Graph attributes:\n" &
        " */\n"
  result &= attrList(g.graphAttr)
      .map(proc(a: string): string = &"{a};\n")
      .join()
  result &= "\n\n"

proc exportNodes(g: Graph): string =
  result &= "/*\n" &
        " * Nodes:\n" &
        " */\n"
  for pair in g.nodeAttrs.pairs:
    let (node, attrs) = pair
    result &= &"{node} {exportAttrList(attrs)};\n"
  result &= "\n\n"

proc exportEdges(g: Graph): string =
  result &= "/*\n" &
        " * Edges:\n" &
        " */\n"

  let edgeSymbol =
    if g.isDirected: "->"
    else: "--"

  for edge in g.iterEdges():
    if len(edge.key) != 0:
      result &= &"//key={edge.key}\n"
    let attrs =
      if edge in g.edgeAttrs:
        exportAttrList(g.edgeAttrs[edge])
      else: ""
    result &= &"{edge.a} {edgeSymbol} {edge.b} {attrs};\n"

proc exportSubGraphs(g: Graph): string =
  for i, sub in g.subGraphs:
    doAssert sub.kind == gkSubgraph
    result &= &"subgraph {sub.clusterName} " & "{\n"
    result &= sub.exportAttributes()
    result &= sub.exportNodes()
    result &= sub.exportEdges()
    result &= "}\n\n"

proc exportDot*(self: Graph): string =
  ## Returns a string describing the graph GraphViz's
  ## `dot language <https://en.wikipedia.org/wiki/DOT_(graph_description_language)>`_.

  let graphType =
    if self.isDirected: "digraph"
    else: "graph"

  let name = self.name

  result = &"strict {graphType} {name} {{\n"
  result &= self.exportSubGraphs()

  result &= self.exportAttributes()
  result &= self.exportNodes()
  result &= self.exportEdges()

  result &= "}\n"

proc checkGvInstalled: bool =
  let command = GV_PATH & "dot"
  try:
    let (_, exitCode) = execCmdEx(&"{command} -V", options={poUsePath})
    return exitCode >= 0
  except Exception:
    return false

proc exportImage*(self: Graph, fileName:string="",
          layout="dot", format="svg") =
  ## Exports the graph as an image file.
  ##
  ## ``filename`` - the name of the file to export to. Should include ".png"
  ## or the appropriate file extension. If none is given, it will default to
  ## the name of the graph. If that is ``nil``, it will default to
  ## ``graph.png``
  ##
  ## ``layout`` - which of the GraphViz layout engines to use. Default is
  ## ``dot``. Can be one of: ``dot``, ``neato``, ``fdp``, ``sfdp``, ``twopi``,
  ## ``circo`` (or others if you have them installed).
  ##
  ## ``format`` - the output format to export to. The default is ``png``.
  ## You can specify more details with
  ## ``"{format}:{rendering engine}:{library}"``.
  ## (See `GV command-line docs <http://www.graphviz.org/doc/info/command.html>`_
  ## for more details)
  let file =
    if len(fileName) != 0 and len(self.name) != 0:
      &"{self.name}.{format}"
    elif len(fileName) == 0:
      &"graph.{format}"
    else:
      fileName

  let command = GV_PATH & "dot"

  if not checkGvInstalled():
    raise newException(OSError, &"Unable to find the GraphViz binary. Do you have GraphViz installed and in your PATH? (Tried to run command `{command}`. If `dot` is not in your path, you can call `setGraphVizPath()` to tell nimGraphViz where it is.")

  let text = self.exportDot()
  let args = &"-K{layout} -o{file} -T{format} -q"
  let dotFile = file.replace(&".{format}", ".dot")
  writeFile(dotFile, text)

  shell:
    ($command) ($dotFile) ($args)
    rm ($dotFile)

if isMainModule:
  var graph = newGraph(directed=true)
  graph.graphAttr["fontsize"] = "32"
  graph.graphAttr["label"] = "Test Graph"
  graph.addEdge("a", "b", "a-to-b", [("label", "A to B")])
  graph.addEdge("c", "b", "c-to-b", [("style", "dotted")])
  graph.addEdge("b", "a", "b-to-a")
  graph.addNode("c", [("color", "blue"), ("shape", "box"),
            ("style", "filled"), ("fontcolor", "white")])
  graph.addNode("d", [("lable", "node")])

  assert graph.nodes.len == 4
  assert graph.edges.len == 3
  assert graph.edges("a").len == 2
  assert graph.edges("d").len == 0
  assert "a" in graph.nodes
  assert "b" in graph.nodes
  assert "c" in graph.nodes
  assert "d" in graph.nodes
  assert ("a", "b", "a-to-b") in graph.edges("a")


  echo "Example DOT graph:"
  echo graph.exportDot()
  echo "\nExporting graph as PNG..."
  # set the location of the `dot` program if not in your path:
  # setGraphVizPath(r"C:\Program Files (x86)\Graphviz2.38\bin\")
  graph.exportImage("test_graph.png")
