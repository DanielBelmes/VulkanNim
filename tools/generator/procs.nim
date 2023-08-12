# std dependencies
import std/strformat
# Generator dependencies
import ./common


proc generateProcsFile *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_procs.nim"
  const genTemplate = """
#[
=====================================

Procedures

=====================================
]#
"""
  writeFile(outputDir,fmt genTemplate)

