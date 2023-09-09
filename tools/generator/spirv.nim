# Generator dependencies
import ./common

proc readSpirvCapabilities *(gen :var Generator; node :XmlNode) :void=
  if node.tag != "spirvcapabilities": raise newException(ParsingError, &"XML data:\n{$node}\n\nTried to read spirvcapability data from a node that is not known to contain them:\n  └─> {node.tag}\n")
  node.checkKnownKeys(SpirvCapData, ["comment"], KnownEmpty=[])
  #ignored: capabilities.comment
  for cap in node:
    if cap.tag notin ["spirvcapability"]: raise newException(ParsingError, &"XML data:\n{$cap}\n\nTried to read single spirvcapability data from an entry that is not known to contain them:\n  └─> {cap.tag}\n")
    cap.checkKnownKeys(SpirvCapData, ["name"], KnownEmpty=[])
    var capability = SpirvCapData(
      xmlLine : cap.lineNumber,
      ) # << SpirvCapData( ... )
    for sub in cap:
      if sub.tag notin ["enable"]: raise newException(ParsingError, &"XML data:\n{$sub}\n\nTried to read spirvcapability feature data from a subnode that is not known to contain them:\n  └─> {sub.tag}\n")
      sub.checkKnownKeys(SpirvCapEnableData,
        ["version", "feature", "requires", "struct", "extension", "member", "property", "value", "alias"], KnownEmpty=[])
      capability.enable.add SpirvCapEnableData(
        version   : sub.attr("version"),
        feature   : sub.attr("feature"),
        requires  : sub.attr("requires"),
        struct    : sub.attr("struct"),
        extension : sub.attr("extension"),
        member    : sub.attr("member"),
        property  : sub.attr("property"),
        value     : sub.attr("value"),
        alias     : sub.attr("alias"),
        xmlLine   : sub.lineNumber,
        ) # << SpirvCapEnableData( ... )
    # Add the capability to the registry
    if gen.registry.spirvCapabilities.containsOrIncl( cap.attr("name"), capability):
      duplicateAddError("SpirvCapData", cap.attr("name"), cap.lineNumber)

proc readSpirvExtensions *(gen :var Generator; node :XmlNode) :void=
  if node.tag != "spirvextensions": raise newException(ParsingError, &"XML data:\n{$node}\n\nTried to read spirvextension data from a node that is not known to contain them:\n  └─> {node.tag}\n")
  node.checkKnownKeys(SpirvExtData, ["comment"], KnownEmpty=[])
  #ignored: extensions.comment
  for ext in node:
    if ext.tag notin ["spirvextension"]: raise newException(ParsingError, &"XML data:\n{$ext}\n\nTried to read single spirvextension data from an entry that is not known to contain them:\n  └─> {ext.tag}\n")
    ext.checkKnownKeys(SpirvExtData, ["name"], KnownEmpty=[])
    var extension = SpirvExtData(
      xmlLine : ext.lineNumber,
      ) # << SpirvExtData( ... )
    # TODO ext.enable (list)
    for sub in ext:
      if sub.tag notin ["enable"]: raise newException(ParsingError, &"XML data:\n{$sub}\n\nTried to read spirvextension feature data from a subnode that is not known to contain them:\n  └─> {sub.tag}\n")
      sub.checkKnownKeys(SpirvExtEnableData, ["version", "extension"], KnownEmpty=[])
      extension.enable.add SpirvExtEnableData(
        version   : ext.attr("version"),
        extension : ext.attr("extension"),
        xmlLine   : ext.lineNumber,
        ) # << SpirvExtEnableData( ... )
    # Add the extension to the registry
    if gen.registry.spirvExtensions.containsOrIncl( ext.attr("name"), extension):
      duplicateAddError("SpirvExtData", ext.attr("name"), ext.lineNumber)


