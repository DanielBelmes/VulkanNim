# Generator dependencies
import ./base


proc generateStructs *(gen :Generator; C_like :static bool= true) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_structs.nim"
  const genTemplate = """
#[
=====================================

Structs

=====================================
]#
"""
  writeFile(outputDir,fmt genTemplate)

