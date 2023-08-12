# std dependencies
import std/strformat
# Generator dependencies
import ./common

proc readFormats *(gen :var Generator; node :XmlNode) :void=  discard

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

