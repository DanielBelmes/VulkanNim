# std dependencies
import std/strformat
# Generator dependencies
import ./common


proc generateFormatsFile *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_formats.nim"
  const genTemplate = """
#[
=====================================

Formats

=====================================
]#
"""
  writeFile(outputDir,fmt genTemplate)

