# Package

version       = "0.2.0"
author        = "Quinn Freedman"
description   = "Nim bindings for the GraphViz tool and the DOT graph language"
license       = "MIT"
srcDir        = "src"
when system.hostOS == "windows":
  bin           = @["nimgraphviz.exe"]
else:
  bin           = @["nimgraphviz"]

# Dependencies

requires "nim >= 0.18.0"
