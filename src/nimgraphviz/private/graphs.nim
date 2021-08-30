import os
import osproc
import streams
import strformat
import strutils

import "./edges"

import tables
export tables


type
  NodeCollection* = ref object of RootObj
    ## Base type for both types of graphs.
    ## You should not have to instanciate it directly.
    name*: string    ## The name of the graph
    graphAttr*: Table[string, string]  ## A table of key-value pairs
                       ## describing the layout and
                       ## appearence of the graph
    nodeAttrs*: Table[string, Table[string, string]] ## A table of all the nodes and their attributes

  Graph* = ref object of NodeCollection
    ## This types models a non-oriented graph.
    subGraphs: seq[Graph] # a graph may have multiple sub graphs
    edges*: Table[Edge, Table[string, string]]

  DiGraph* = ref object of NodeCollection
    ## This type models an oriented graph.
    subGraphs: seq[DiGraph] # a graph may have multiple sub graphs
    edges*: Table[DiEdge, Table[string, string]]

  GenericGraph* = Graph or DiGraph


func newGraph*(): Graph =
  result = Graph(
    graphAttr: initTable[string, string](),
    nodeAttrs: initTable[string, Table[string, string]](),
    subGraphs: newSeq[Graph](),
    edges: initTable[Edge, Table[string, string]](),
  )

func newDiGraph*(): DiGraph =
  result = DiGraph(
    graphAttr: initTable[string, string](),
    nodeAttrs: initTable[string, Table[string, string]](),
    subGraphs: newSeq[DiGraph](),
    edges: initTable[DiEdge, Table[string, string]](),
  )

#TODO: find a way to properly merge the two implementations ? (generics)
func newSubGraph*(parent: Graph): Graph =
  ## Returns a new graph, attached to its parent as subgraph.
  ## Some graphviz engines have a specific behaviour when the name of the
  ## subgraph begins with "cluster" -- see the official website.
  ## Note that the subgraphs are full graphs themselves: you can treat them
  ## as standalone objects (e.g. when exporting images)
  ## Note: All subgraphs must keep their parent's "orientedness"
  result = newGraph()
  parent.subGraphs.add(result)
func newSubGraph*(parent: DiGraph): DiGraph =
  ## Returns a new digraph, attached to its parent as subgraph.
  ## Some graphviz engines have a specific behaviour when the name of the
  ## subgraph begins with "cluster" -- see the official website.
  ## Note that the subgraphs are full graphs themselves: you can treat them
  ## as standalone objects (e.g. when exporting images)
  ## Note: All subgraphs must keep their parent's "orientedness"
  result = newDiGraph()
  parent.subGraphs.add(result)

# TODO: find a way to properly merge the two implementations ? (generics)
func addEdge*(self: Graph, edge: Edge, attr: varargs[(string, string)]) =
  ## Add an edge to the graph. Optional attributes may be specified as a serie
  ## of (key, value) tuples.
  if not self.edges.hasKey(edge) :
    self.edges[edge] = initTable[string, string]()

  for (k,v) in attr:
    self.edges[edge][k] = v
func addEdge*(self: DiGraph, edge: DiEdge, attr: varargs[(string, string)]) =
  ## Add an edge to the graph. Optional attributes may be specified as a serie
  ## of (key, value) tuples.
  if not self.edges.hasKey(edge) :
    self.edges[edge] = initTable[string, string]()

  for (k,v) in attr:
    self.edges[edge][k] = v

func addNode*(self: GenericGraph, node: string, attr: varargs[(string, string)]) =
  ## Add a node to the graph. Optional attributes may be specified as a serie
  ## of (key, value) tuples.
  ## Note that you don't need to add a node manually if it appears in an edge.
  if not self.nodeAttrs.hasKey(node) :
    self.nodeAttrs[node] = initTable[string, string]()

  for (k,v) in attr:
    self.nodeAttrs[node][k] = v


func `[]`*(self: GenericGraph, gAttr: string): string =
  ## Shortcut to access graph attributes
  self.graphAttr[gAttr]
func `[]=`*(self: GenericGraph, gAttr: string, value: string) =
  ## Shortcut to set graph attributes
  self.graphAttr[gAttr] = value

func `[]`*(self: GenericGraph, node: string): Table[string, string] =
  ## Shortcut to access node attributes
  ## Returns the attribute table for the given node.
  ## Throws the relevant exception from Table when the node does not exist.
  self.nodeAttrs[node]
func `[]`*(self: GenericGraph, node: string, key: string): string =
  ## Shortcut to access node attributes
  ## Returns the attribute value for the given node, given key.
  ## Throws the relevant exception from Table when the node does not exist.
  self.nodeAttrs[node][key]
func `[]=`*(self: GenericGraph, node: string, key: string, value: string) =
  ## Shortcut to edit node attributes.
  ## If the node hasn't got a table yet, it gets one beforehand.
  self.addNode(node)
  self.nodeAttrs[node][key] = value


# TODO: find a way to properly merge the two implementations ? (generics)
func `[]`*(self: Graph, edge: Edge): Table[string, string] =
  ## Shortcut to access edge attributes
  ## Returns the attribute table for the given edge.
  ## Throws the relevant exception from Table when the edge does not exist.
  self.edges[edge]
func `[]`*(self: DiGraph, edge: DiEdge): Table[string, string] =
  ## Shortcut to access edge attributes
  ## Returns the attribute table for the given edge.
  ## Throws the relevant exception from Table when the edge does not exist.
  self.edges[edge]
func `[]`*(self: Graph, edge: Edge, key: string): string =
  ## Shortcut to access edge attributes
  ## Returns the attribute value for the given edge, given key.
  ## Throws the relevant exception from Table when the edge does not exist.
  self.edges[edge][key]
func `[]`*(self: DiGraph, edge: DiEdge, key: string): string =
  ## Shortcut to access edge attributes
  ## Returns the attribute value for the given edge, given key.
  ## Throws the relevant exception from Table when the edge does not exist.
  self.edges[edge][key]
func `[]=`*(self: Graph, edge: Edge, key: string, value: string) =
  ## Shortcut to edit edge attributes.
  ## If the edge doesn't exist in the graph yet, it is created beforehand.
  self.addEdge(edge)
  self.edges[edge][key] = value
func `[]=`*(self: DiGraph, edge: DiEdge, key: string, value: string) =
  ## Shortcut to edit edge attributes.
  ## If the edge doesn't exist in the graph yet, it is created beforehand.
  self.addEdge(edge)
  self.edges[edge][key] = value



# TODO: find a way to properly merge the two implementations ? (generics)
iterator iterEdges*(self: Graph, node: string): Edge =
  ## Iterate over all the edges adjacent to a given node
  for edge in self.edges.keys() :
    if edge.a == node or edge.b == node:
      yield edge
iterator iterEdges*(self: DiGraph, node: string): DiEdge =
  ## Iterate over all the edges adjacent to a given node
  for edge in self.edges.keys() :
    if edge.a == node or edge.b == node:
      yield edge

iterator iterEdgesIn*(self: DiGraph, node: string): DiEdge =
  ## Oriented version: yields only inbound edges
  for edge in self.edges.keys() :
    if edge.b == node:
      yield edge
iterator iterEdgesOut*(self: DiGraph, node: string): DiEdge =
  ## Oriented version: yields only outbound edges
  for edge in self.edges.keys() :
    if edge.a == node:
      yield edge


func exportIdentifier(identifier:string): string =
  if identifier.validIdentifier() :
    return identifier

  # if needs be, escape '"' and surround in quotes (do not replace '\' !!)
  return "\"" & identifier.replace("\"", "\\\"") & "\""

func `$`(edge: Edge): string =
  exportIdentifier(edge.a) & " -- " & exportIdentifier(edge.b)
func `$`(edge: DiEdge): string =
  exportIdentifier(edge.a) & " -> " & exportIdentifier(edge.b)

func exportSubDot(self: GenericGraph): string # forward declaration

func tableToAttributes(tbl: Table[string, string]): seq[string] =
  for (key, value) in tbl.pairs() :
    result.add exportIdentifier(key) & "=" & exportIdentifier(value)

func exportAttributes(self: GenericGraph): string =
  result = tableToAttributes(self.graphAttr).join(";\n")
  if len(result) > 0 :
    result &= "\n"

func exportNodes(self: GenericGraph): string =
  for (node, tbl) in self.nodeAttrs.pairs() :
    result &= exportIdentifier(node)
    if tbl.len > 0:
      result &= " ["
      result &= tableToAttributes(tbl).join(", ")
      result &= "]"
    result &= ";\n"

func exportEdges(self: GenericGraph): string =
  for (edge, tbl) in self.edges.pairs() :
    result &= $edge
    if tbl.len > 0:
      result &= " ["
      result &= tableToAttributes(tbl).join(", ")
      result &= "]"
    result &= ";\n"

func buildBody(self: GenericGraph): string =
  result = "{\n"
  for sub in self.subGraphs :
    result &= exportSubDot(sub)
  result &= self.exportAttributes()
  result &= self.exportNodes()
  result &= self.exportEdges()
  result &= "}\n"

func exportSubDot(self: GenericGraph): string =
  result = "subgraph " & exportIdentifier(self.name) & " " & self.buildBody()

func exportDot*(self: Graph): string =
  ## Returns the dot script corresponding to the graph, including subgraphs.
  result = "strict graph " & exportIdentifier(self.name) & " " & self.buildBody()
func exportDot*(self: DiGraph): string =
  ## Returns the dot script corresponding to the graph, including subgraphs.
  result = "strict digraph " & exportIdentifier(self.name) & " " & self.buildBody()

proc exportImage*(self: GenericGraph, fileName: string,
          layout="dot", format="", exec="dot") =
  ## Exports the graph as an image file.
  ##
  ## ``filename`` - the name of the file to export to. Should include ".png"
  ## or the appropriate file extension.
  ##
  ## ``layout`` - which of the GraphViz layout engines to use. Default is
  ## ``dot``. Can be one of: ``dot``, ``neato``, ``fdp``, ``sfdp``, ``twopi``,
  ## ``circo`` (or others if you have them installed).
  ##
  ## ``format`` - the output format to export to. The default is ``svg``.
  ## If not specified, it is deduced from the file name.
  ## You can specify more details with
  ## ``"{format}:{rendering engine}:{library}"``.
  ## (See `GV command-line docs <http://www.graphviz.org/doc/info/command.html>`_
  ## for more details)
  ##
  ## ``exec`` - path to the ``dot`` command; use this when ``dot`` is not in
  ## your PATH

  # This blocks determines the output file name and its content type
  # fileName has precedence over self.name
  # The content type is deduced from the file name unless explicitely specified.

  var (dir, name, ext) = splitFile(fileName)
  if len(dir) == 0 :
    dir = "." # current dir

  if ext == "." or ext == "":
    ext = ".svg" # default format : SVG

  let actual_format =
    if format != "" :
       format
    else :
      ext[1..^1] # remove the '.' in first position
  let file = &"{dir}/{name}{ext}"

  let text = self.exportDot()
  let args = [
    &"-K{layout}",
    &"-o{file}",
    &"-T{actual_format}",
    "-q"
  ]
  let process =
    try :
      startProcess(exec, args=args, options={poUsePath})
    except OSError :
      # "command not found", but I think the default message is explicit enough
      # the try/except block is just there to show where the error can arise
      raise
  let stdin = process.inputStream
  let stderr = process.errorStream
  stdin.write(text)
  stdin.close()
  let errcode = process.waitForExit()
  let errormsg = stderr.readAll()
  process.close()
  if errcode != 0:
    raise newException(OSError, fmt"[errcode {errcode}] " & errormsg)
