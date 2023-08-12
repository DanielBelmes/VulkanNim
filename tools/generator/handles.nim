# std dependencies
import std/strformat
# Generator dependencies
import ./common


proc generateHandlesFile *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_handles.nim"
  const genTemplate = """
#[
=====================================

Handles

=====================================
]#
"""
  writeFile(outputDir,fmt genTemplate)

