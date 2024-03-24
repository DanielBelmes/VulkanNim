# Generator dependencies
import ./common


proc readVendorTags *(parser :var Parser; node :XmlNode) :void=
  ## Treats the given node as a VendorTags block, and adds its contents to the respective generator registry field.
  if node.tag != "tags": raise newException(ParsingError, &"Tried to read tags data from a node that is not known to contain tags:\n  └─> {node.tag}\nIts XML data is:\n{$node}\n")
  node.checkKnownKeys(TagData, ["comment"])
  for entry in node:
    if entry.tag != "tag": raise newException(ParsingError, &"Tried to read tag data from a subnode that is not known to contain single tag info:\n  └─> {entry.tag}\nIts XML data is:\n{$entry}\n")
    entry.checkKnownKeys(TagData, ["name", "author", "contact"])
    if parser.registry.tags.containsOrIncl(entry.attr("name").removeExtraSpace(), TagData(
      xmlLine : entry.lineNumber,
      author  : entry.attr("author").removeExtraSpace(),
      contact : entry.attr("contact").removeExtraSpace()
      )): duplicateAddError("Tag",entry.attr("name"),entry.lineNumber)

