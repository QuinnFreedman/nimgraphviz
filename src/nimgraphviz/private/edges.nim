import hashes

type
  Edge* = object
    ## Represents a non-oriented edge
    ## `a -- b` in DOT syntax.
    a*, b*: string
  DiEdge* = object
    ## Represents an oriented edge
    ## `a -> b` in DOT syntax.
    a*, b*: string

func `==`*(edge1, edge2: Edge):bool =
  ## N.B.: `a--b` == `b--a`
  return
    (edge1.a == edge2.a and edge1.b == edge2.b) or
    (edge1.a == edge2.b and edge1.b == edge2.a)

func `==`*(edge1, edge2:DiEdge):bool =
  ## N.B.: `a->b` != `b->a`
  return
    (edge1.a == edge2.a and edge1.b == edge2.b)

func hash*(edge:Edge): Hash =
  # use xor instead of !& to ensure Edge(a,b) == Edge(b, a)
  result = hash(edge.a) xor hash(edge.b)
  result = !$result

func hash*(edge:DiEdge): Hash =
  result = hash(edge.a) !& hash(edge.b)
  result = !$result

func `--`*(a, b:string):Edge =
  ## Convenience syntax for Edge(...)
  result = Edge(a:a, b:b)

func `->`*(a,b:string):DiEdge =
  ## Convenience syntax for DiEdge(...)
  result = DiEdge(a:a, b:b)
