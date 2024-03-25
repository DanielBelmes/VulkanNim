# Generator dependencies
import ./base

proc generateTypes *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_types.nim"
  const genTemplate = """
#[
=====================================

Types

=====================================
]#
"""
  writeFile(outputDir,fmt genTemplate)

