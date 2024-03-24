import ./base; export base
import ./enums
import ./extensions
import ./features
import ./formats
import ./license
import ./platforms
import ./procs
import ./spirv
import ./sync
import ./types
import ./vendors

proc readComments (parser :var Parser; node :XmlNode) :void=
  ## Treats the given node as a comment block, and adds its contents to the generator registry.
  if node.innerText.contains("Copyright"): parser.readLicense(node); return
  parser.registry.rootComments.add CommentData(
    text    : node.innerText,
    xmlLine : node.lineNumber )

proc readRegistry *(parser :var Parser) :void=
  ## Reads the XML file and converts its data into our Intermediate Representation object format
  for child in parser.doc:
    case child.tag
    of "platforms"         : parser.readPlatforms(child)
    of "tags"              : parser.readVendorTags(child)
    of "types"             : parser.readTypes(child)
    of "enums"             : parser.readEnum(child)
    of "commands"          : parser.readProcs(child)
    of "feature"           : parser.readFeatures(child)
    of "extensions"        : parser.readExtensions(child)
    of "formats"           : parser.readFormats(child)
    of "spirvcapabilities" : parser.readSpirvCapabilities(child)
    of "spirvextensions"   : parser.readSpirvExtensions(child)
    of "sync"              : parser.readSync(child)
    of "comment"           : parser.readComments(child)
    else: raise newException(ParsingError, &"Unknown tag in readRegistry:\n └─> {child.tag}\n")
