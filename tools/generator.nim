{.experimental: "codeReordering".}
import strutils, os, xmlparser, xmltree, strformat, streams
import nstd

type Generator = object
  doc: XmlNode
  api: string ## needs to be of value "vulkan" or "vulkansc"

proc generateApiFile(gen: Generator): void =
  let outputDir = fmt"./src/VulkanNim/{gen.api}.nim"
  const genTemplate = """
include ./dynamic
import {gen.api}_enum;export {gen.api}_enum
"""
  writeFile(outputDir,fmt genTemplate)

proc generateTypesFile(gen: Generator): void =
  let outputDir = fmt"./src/VulkanNim/{gen.api}_types.nim"
  const genTemplate = """
#[
=====================================

Types

=====================================
]#
"""
  writeFile(outputDir,fmt genTemplate)

proc generateExtensionInspectionFile(gen: Generator): void =
  let outputDir = fmt"./src/VulkanNim/{gen.api}_extension_inspection.nim"
  const genTemplate = """
#[
=====================================

Extension Inspection

=====================================
]#
"""
  writeFile(outputDir,fmt genTemplate)

proc generateFormatsFile(gen: Generator): void =
  let outputDir = fmt"./src/VulkanNim/{gen.api}_formats.nim"
  const genTemplate = """
#[
=====================================

Formats

=====================================
]#
"""
  writeFile(outputDir,fmt genTemplate)

proc generateEnumFile(gen: Generator): void =
  let outputDir = fmt"./src/VulkanNim/{gen.api}_enums.nim"
  const genTemplate = """
#[
=====================================

Enums

=====================================
]#
"""
  writeFile(outputDir,fmt genTemplate)

proc generateProcsFile(gen: Generator): void =
  let outputDir = fmt"./src/VulkanNim/{gen.api}_procs.nim"
  const genTemplate = """
#[
=====================================

Procedures

=====================================
]#
"""
  writeFile(outputDir,fmt genTemplate)

proc generateHandlesFile(gen: Generator): void =
  let outputDir = fmt"./src/VulkanNim/{gen.api}_handles.nim"
  const genTemplate = """
#[
=====================================

Handles

=====================================
]#
"""
  writeFile(outputDir,fmt genTemplate)

proc generateStructsFile(gen: Generator): void =
  let outputDir = fmt"./src/VulkanNim/{gen.api}_structs.nim"
  const genTemplate = """
#[
=====================================

Structs

=====================================
]#
"""
  writeFile(outputDir,fmt genTemplate)

proc main() =
  let args = getArgs()
  var XML, api: string
  if args.len == 2:
    if args[1] != "vulkan" or args[1] != "vulkansc":
      raise newException(IOError, "The vk.xml spec file path needs to be passed to the generator as its first argument.")
    api = args[1]
  elif args.len == 1:
    if not args[0].endsWith(".xml"): raise newException(IOError, "The vk.xml spec file path needs to be passed to the generator as its first argument.")
    api = "vulkan"
    XML = args[0]
  elif args.len == 0:
    raise newException(IOError, "No arguments provided [TODO] be more helpful")
  else:
    raise newException(IOError, "I don't know why you have so many arguments")
  let file = newFileStream(XML, fmRead)

  let generator = Generator(doc: file.parseXml(), api: api)

  generator.generateApiFile()
  generator.generateTypesFile()
  generator.generateExtensionInspectionFile()
  generator.generateFormatsFile()
  generator.generateEnumFile()
  generator.generateProcsFile()
  generator.generateHandlesFile()
  generator.generateStructsFile()


when isMainModule: main()
