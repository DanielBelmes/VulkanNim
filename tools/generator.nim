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
import ./generator/spirv

# TODO: Move to the ./generator/*.nim file they should belong to
proc readFeatures *(gen :var Generator; node :XmlNode) :void=  discard
proc readPlatforms *(gen :var Generator; node :XmlNode) :void=  discard
proc readSync *(gen :var Generator; node :XmlNode) :void=  discard
proc readTags *(gen :var Generator; node :XmlNode) :void=  discard

proc readRegistry *(gen :var Generator) :void=
  for child in gen.doc:
    let value = child.tag
    if value == "commands":
      discard
    elif value == "comment":
      if child.innerText.contains("Copyright"):
        gen.registry.vulkanLicenseHeader = child.innerText # [TODO] will have to generate real copyright message from this
    elif value == "enums":
      gen.readEnums(child)
    elif value == "extensions":
      gen.readExtensions(child)
    elif value == "feature":
      gen.readFeatures(child)
    elif value == "formats":
      gen.readFormats(child)
    elif value == "platforms":
      gen.readPlatforms(child)
    elif value == "spirvcapabilities":
      gen.readSpirvCapabilities(child)
    elif value == "spirvextensions":
      gen.readSpirvExtensions(child)
    elif value == "sync":
      gen.readSync(child)
    elif value == "tags":
      gen.readTags(child)
    elif value == "types":
      gen.readTypes(child)


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

  generator.readRegistry()

  generator.generateApiFile()
  generator.generateTypesFile()
  generator.generateExtensionInspectionFile()
  generator.generateFormatsFile()
  generator.generateEnumFile()
  generator.generateProcsFile()
  generator.generateHandlesFile()
  generator.generateStructsFile()


when isMainModule: main()
