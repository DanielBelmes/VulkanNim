# std dependencies
import std/strformat
# Generator dependencies
import ./common


proc generateExtensionInspectionFile *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_extension_inspection.nim"
  const genTemplate = """
#[
=====================================

Extension Inspection

=====================================
]#
"""
  writeFile(outputDir,fmt genTemplate)


