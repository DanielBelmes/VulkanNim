# std dependencies
import std/strformat
import ../customxmlParsing/xmltree
# Generator dependencies
import ./common
import ../helpers

proc readFormats *(gen :var Generator; formats :XmlNode) :void=
  for format in formats:
    var formatData: FormatData
    for dataChild in format:
      case dataChild.tag:
      of "plane":
        formatData.planes.add(PlaneData(
          compatible: dataChild.attr("compatible"),
          heightDivisor: dataChild.attr("heightDivisor"),
          widthDivisor: dataChild.attr("protect"), xmlLine: dataChild.lineNumber))
      of "component":
        formatData.components.add(ComponentData(
            bits: dataChild.attr("bits"),
            name: dataChild.attr("name"),
            numericFormat: dataChild.attr("numericFormat"),
            planeIndex: dataChild.attr("planeIndex"),
            xmlLine: dataChild.lineNumber
        ))
      of "spirvimageformat":
        formatData.spirvImageFormat = dataChild.attr("name")
      else:
        raise newException(ParsingError,"Unkown format child in format: " & $format)
      formatData.blockExtent = dataChild.attr("blockExtent")
      formatData.blockSize = dataChild.attr("blockSize")
      formatData.chroma = dataChild.attr("chroma")
      formatData.classAttribute = dataChild.attr("classAttribute")
      formatData.compressed = dataChild.attr("compressed")
      formatData.packed = dataChild.attr("packed")
      formatData.texelsPerBlock = dataChild.attr("texelsPerBlock")
      formatData.xmlLine = format.lineNumber
    if gen.registry.formats.containsOrIncl(format.attr("name"),formatData):
      duplicateAdd("Format",format.attr("name"),format.lineNumber)

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

