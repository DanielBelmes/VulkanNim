# Generator dependencies
import ./common


proc generateStructs *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_structs.nim"
  const genTemplate = """
#[
=====================================

Structs

=====================================
]#
"""
  writeFile(outputDir,fmt genTemplate)

