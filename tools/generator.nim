# std dependencies
import strutils, os, xmlparser, xmltree, strformat, streams
# External dependencies
import nstd
# Generator dependencies
import ./generator/common
import ./generator/api
import ./generator/enums
import ./generator/extensions
import ./generator/formats
import ./generator/handles
import ./generator/procs
import ./generator/structs
import ./generator/types


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
