# Generator dependencies
import ./base


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

