# std dependencies
import std/streams
# External dependencies
import nstd
# Generator dependencies
import ./generator/base
import ./generator/api
import ./generator/enums
import ./generator/extensions
import ./generator/features
import ./generator/formats
import ./generator/handles
import ./generator/platforms
import ./generator/procs
import ./generator/structs
import ./generator/types
import ./generator/spirv
import ./generator/sync
import ./generator/license
import ./generator/vendors

proc readComments (gen :var Generator; node :XmlNode) :void=
  ## Treats the given node as a comment block, and adds its contents to the generator registry.
  if node.innerText.contains("Copyright"): gen.readLicense(node); return
  gen.registry.rootComments.add CommentData(
    text    : node.innerText,
    xmlLine : node.lineNumber )

proc readRegistry *(gen :var Generator) :void=
  ## Reads the XML file and converts its data into our Intermediate Representation object format
  for child in gen.doc:
    case child.tag
    of "platforms"         : gen.readPlatforms(child)
    of "tags"              : gen.readVendorTags(child)
    of "types"             : gen.readTypes(child)
    of "enums"             : gen.readEnum(child)
    of "commands"          : gen.readProcs(child)
    of "feature"           : gen.readFeatures(child)
    of "extensions"        : gen.readExtensions(child)
    of "formats"           : gen.readFormats(child)
    of "spirvcapabilities" : gen.readSpirvCapabilities(child)
    of "spirvextensions"   : gen.readSpirvExtensions(child)
    of "sync"              : gen.readSync(child)
    of "comment"           : gen.readComments(child)
    else: raise newException(ParsingError, &"Unknown tag in readRegistry:\n └─> {child.tag}\n")

#_______________________________________
# Generator Entry Point
#___________________
# CLI helper docs
const DefaultAPI = "vulkan" 
const ValidAPIs  = ["vulkan", "vulkansc"]
const Help = &"""
Usage:
- First argument:  Must always be a valid vk.xml spec file.
  Note: Validity of the file is only checked by extension, and will crash the XML parser if its has invalid xml contents.
- Second argument (optional):
  A targetAPI keyword can be provided. Valid keywords:  {ValidAPIs}
  Will default to "{DefaultAPI}" when omitted.
"""
static:assert DefaultAPI in ValidAPIs
#___________________
# Entry Point
proc main=
  # Interpret the arguments given to the generator
  let args = nstd.getArgs()
  var XML, targetAPI: string
  if args.len in 1..2:
    if not args[0].endsWith(".xml"): raise newException(ArgsError, &"The first argument input must be a valid .xml file. See {Help}")
    XML = args[0]
  if args.len == 2:
    if args[1] notin ValidAPIs: raise newException(ArgsError, "The desired target API needs to be either omitted, or passed to the generator as its second argument. The known valid options are:\n{ValidAPIs}")
    targetAPI = args[1]
  elif args.len == 1:
    targetAPI = DefaultAPI # Assume normal vulkan (not sc) when omitted.
  elif args.len == 0 : raise newException(ArgsError, &"No arguments provided. See {Help}")
  else               : raise newException(ArgsError, &"Too many arguments provided. See {Help}")

  # Read the file into an XML tree
  var file = newFileStream(XML,fmRead)
  var generator = Generator(
    doc : file.parseXml(),
    api : targetAPI  )

  # Parse the XML into our Intermediate Representation objects
  generator.readRegistry()

  # Generate the code files
  generator.generateAPI()
  generator.generateExtensionInspection()
  generator.generateTypes()
  generator.generateFormats()
  generator.generateEnums()
  generator.generateProcs()
  generator.generateHandles()
  generator.generateStructs()


when isMainModule: main()
