# std dependencies
import std/strformat, xmltree
# Generator dependencies
import ./common

proc readTypes *(gen :var Generator; node :XmlNode) :void=  discard

proc generateTypesFile *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_types.nim"
  const genTemplate = """
#[
=====================================

Types

=====================================
]#
"""
  writeFile(outputDir,fmt genTemplate)

