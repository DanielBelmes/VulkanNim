# Generator dependencies
import ./common

proc readSpirvCapabilities *(gen :var Generator; node :XmlNode) :void=
  if node.tag != "spirvcapabilities": raise newException(ParsingError, &"XML data:\n{$node}\n\nTried to read spirvcapability data from a node that is not known to contain them:\n  └─> {node.tag}\n")
  node.checkKnownKeys(SpirvCapData, ["comment"], KnownEmpty=[])
  # TODO capabilities.comment
  for cap in node:
    if cap.tag notin ["spirvcapability"]: raise newException(ParsingError, &"XML data:\n{$cap}\n\nTried to read single spirvcapability data from an entry that is not known to contain them:\n  └─> {cap.tag}\n")
    cap.checkKnownKeys(SpirvCapData, ["name"], KnownEmpty=[])
    # TODO cap.name
    # TODO cap.enable (list)
    for sub in cap:
      if sub.tag notin ["enable"]: raise newException(ParsingError, &"XML data:\n{$sub}\n\nTried to read spirvcapability feature data from a subnode that is not known to contain them:\n  └─> {sub.tag}\n")
      sub.checkKnownKeys(SpirvCapData,
        ["version", "feature", "requires", "struct", "extension", "member", "property", "value", "alias"], KnownEmpty=[])
      # TODO sub.version
      # TODO sub.feature
      # TODO sub.requires
      # TODO sub.struct
      # TODO sub.extension
      # TODO sub.member
      # TODO sub.property
      # TODO sub.value
      # TODO sub.alias

proc readSpirvExtensions *(gen :var Generator; node :XmlNode) :void=
  if node.tag != "spirvextensions": raise newException(ParsingError, &"XML data:\n{$node}\n\nTried to read spirvextension data from a node that is not known to contain them:\n  └─> {node.tag}\n")
  node.checkKnownKeys(SpirvExtData, ["comment"], KnownEmpty=[])
  # TODO extensions.comment
  for ext in node:
    if ext.tag notin ["spirvextension"]: raise newException(ParsingError, &"XML data:\n{$ext}\n\nTried to read single spirvextension data from an entry that is not known to contain them:\n  └─> {ext.tag}\n")
    ext.checkKnownKeys(SpirvExtData, ["name"], KnownEmpty=[])
    # TODO ext.name
    # TODO ext.enable (list)
    for sub in ext:
      if sub.tag notin ["enable"]: raise newException(ParsingError, &"XML data:\n{$sub}\n\nTried to read spirvextension feature data from a subnode that is not known to contain them:\n  └─> {sub.tag}\n")
      sub.checkKnownKeys(SpirvExtData, ["version", "extension"], KnownEmpty=[])
      # TODO ext.version
      # TODO ext.extension

