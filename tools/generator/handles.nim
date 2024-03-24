# Generator dependencies
import ./base


proc generateHandles *(gen :Generator; C_like :static bool= true) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_handles.nim"
  const genTemplate = """
#[
=====================================

Handles

=====================================
]#
"""
  writeFile(outputDir,fmt genTemplate)

