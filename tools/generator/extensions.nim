# std dependencies
import std/strformat
import ../customxmlParsing/xmltree
# Generator dependencies
import ./common

proc readExtensions *(gen :var Generator; node :XmlNode) :void=  discard

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


