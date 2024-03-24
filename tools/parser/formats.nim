# Generator dependencies
import ./common

proc readFormats *(parser :var Parser; node :XmlNode) :void=
  ## Treats the given node as a formats block, and adds its contents to the generator registry.
  if node.tag != "formats": raise newException(ParsingError, &"XML data:\n{$node}\nError when reading formats data from a node that is not known to contain them:\n  └─> {node.tag}\n")
  node.checkKnownKeys(FormatData, [], KnownEmpty=["formats"])
  for entry in node:
    if entry.tag notin ["format"]: raise newException(ParsingError, &"XML data:\n{$entry}\nError when reading format entry data from an entry that is not known to contain them:\n  └─> {entry.tag}\n")
    entry.checkKnownKeys(FormatData,
      ["blockSize", "class", "name", "packed", "texelsPerBlock", "compressed", "blockExtent", "chroma"],
      KnownEmpty=[])
    var data = FormatData(
      class          : entry.attr("class"),
      blockExtent    : entry.attr("blockExtent"),
      blockSize      : entry.attr("blockSize"),
      chroma         : entry.attr("chroma"),
      compressed     : entry.attr("compressed"),
      packed         : entry.attr("packed"),
      texelsPerBlock : entry.attr("texelsPerBlock"),
      xmlLine        : entry.lineNumber,
      ) # << FormatData( ... )
    for child in entry:
      if child.tag notin ["component", "plane", "spirvimageformat"]: raise newException(ParsingError, &"XML data:\n{$child}\nError when reading component/plane/spirvformat data from an subnode that is not known to contain them:\n  └─> {child.tag}\n")
      case child.tag
      of "plane":
        child.checkKnownKeys(PlaneData, ["widthDivisor", "heightDivisor", "index", "compatible"], KnownEmpty=[])
        data.planes[child.attr("name")] = PlaneData(
          index         : child.attr("index"),
          compatible    : child.attr("compatible"),
          heightDivisor : child.attr("heightDivisor"),
          widthDivisor  : child.attr("widthDivisor"),
          xmlLine       : child.lineNumber )
      of "component":
        child.checkKnownKeys(ComponentData, ["numericFormat", "bits", "name", "planeIndex"], KnownEmpty=[])
        data.components[child.attr("name")] = ComponentData(
          bits          : child.attr("bits"),
          numericFormat : child.attr("numericFormat"),
          planeIndex    : child.attr("planeIndex"),
          xmlLine       : child.lineNumber )
      of "spirvimageformat":
        child.checkKnownKeys(string, ["name"], KnownEmpty=[])
        data.spirvImageFormat = child.attr("name")
    if parser.registry.formats.containsOrIncl( entry.attr("name"), data):
      duplicateAddError("Format",entry.attr("name"),entry.lineNumber)
