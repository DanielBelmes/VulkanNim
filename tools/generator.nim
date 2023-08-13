# std dependencies
import strutils, os, xmlparser, xmltree, strformat, streams, tables, sequtils
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
import helpers

# TODO: Move to the ./generator/*.nim file they should belong to
proc readFeatures *(gen :var Generator; feature :XmlNode) :void=
  var featureData: FeatureData
  featureData.name = feature.attr("name")
  featureData.api = feature.attr("api").split(",")
  featureData.number = feature.attr("number")
  featureData.xmlLine = -1
  for requireOrRemove in feature:
    if requireOrRemove.tag == "require":
      var requireData: RequireData
      requireData.depends = requireOrRemove.attr("depends")
      requireData.xmlLine = -1
      for commandConstantType in requireOrRemove:
        if commandConstantType.kind != xnElement: continue
        if commandConstantType.tag == "type":
          requireData.types.add(commandConstantType.attr("name"))
        if commandConstantType.tag == "enum":
          requireData.constants.add(commandConstantType.attr("name"))
        if commandConstantType.tag == "command":
          requireData.commands.add(commandConstantType.attr("name"))
      featureData.requireData.add(requireData)
    else:
      var removeData: RemoveData
      removeData.xmlLine = -1
      for commandEnumType in requireOrRemove:
        if commandEnumType.kind != xnElement: continue
        if commandEnumType.tag == "type":
          removeData.types.add(commandEnumType.attr("name"))
        if commandEnumType.tag == "enum":
          removeData.enums.add(commandEnumType.attr("name"))
        if commandEnumType.tag == "command":
          removeData.commands.add(commandEnumType.attr("name"))
      featureData.removeData.add(removeData)
  gen.registry.features.add(featureData)

proc readPlatforms *(gen :var Generator; platforms :XmlNode) :void=
  for platform in platforms:
    if gen.registry.platforms.containsOrIncl(platform.attr("name"),
      PlatformData(
        protect: platform.attr("protect"),
        comment: platform.attr("comment")
        )): raise newException(ParsingError, &"Tried to add a repeated Platform that already exists inside the generator : {platform.attr(\"name\")}.")

proc readSync *(gen :var Generator; node :XmlNode) :void=  discard #relies on enum

proc readTags *(gen :var Generator; tags :XmlNode) :void=
  for tag in tags:
    if gen.registry.tags.containsOrIncl(tag.attr("name"),
      TagData(
        author: tag.attr("author"),
        contact: tag.attr("contact"))): raise newException(ParsingError, &"Tried to add a repeated Tag that already exists inside the generator : {tag.attr(\"name\")}.")

proc readRegistry *(gen :var Generator) :void=
  for child in gen.doc:
    let value = child.tag
    if value == "commands":
      discard
    elif value == "comment":
      if child.innerText.contains("Copyright"):
        gen.registry.vulkanLicenseHeader = child.innerText # [TODO] will have to generate real copyright message from this
    elif value == "enums":
      gen.addEnum(child)
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
      raise newException(ArgsError, "The vk.xml spec file path needs to be passed to the generator as its first argument.")
    api = args[1]
  elif args.len == 1:
    if not args[0].endsWith(".xml"): raise newException(ArgsError, "The vk.xml spec file path needs to be passed to the generator as its first argument.")
    api = "vulkan"
    XML = args[0]
  elif args.len == 0:
    raise newException(ArgsError, "No arguments provided [TODO] be more helpful")
  else:
    raise newException(ArgsError, "I don't know why you have so many arguments")
  let file = newFileStream(XML, fmRead)

  var generator = Generator(doc: file.parseXml(), api: api)

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
