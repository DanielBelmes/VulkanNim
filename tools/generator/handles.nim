# Generator dependencies
import ./common


proc generateHandles *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_handles.nim"
  const genTemplate = """
#[
=====================================

Handles

=====================================
]#
"""
  writeFile(outputDir,fmt genTemplate)

