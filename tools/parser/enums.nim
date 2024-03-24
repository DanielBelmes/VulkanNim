# std dependencies
import std/strformat
# Generator dependencies
import ./common


proc addConsts *(parser :var Parser; node :XmlNode) :void=
  ## Treats the given node as a constants block, and adds its contents to the generator registry.
  for entry in node:
    # Add Constant alias to the registry and skip to the next entry
    if entry.attr("alias") != "":
      parser.registry.constantAliases[ entry.attr("alias") ] = AliasData(
        name       : entry.attr("name"),
        deprecated : entry.attr("deprecated"),
        api        : entry.attr("api"),
        xmlLine    : entry.lineNumber )
    # Normal Constant entry
    elif parser.registry.constants.containsOrIncl(entry.attr("name"), ConstantData(
      typ     : entry.attr("type"),
      value   : entry.attr("value"),
      xmlLine : entry.lineNumber,
      )): duplicateAddError("Enum constant",entry.attr("name"),entry.lineNumber)

proc addBitmask *(parser :var Parser; node :XmlNode) :void=
  ## Treats the given node as a bitmask enum, and adds its contents to the respective generator registry field.
  node.checkKnownKeys(BitmaskData, [ "comment", "bitwidth", "require", "type", "name" ])
  var data = BitmaskData(
    comment   : node.attr("comment"),
    bitwidth  : node.attr("bitwidth"),
    require   : node.attr("require"),
    typ       : node.attr("type"),
    xmlLine   : node.lineNumber,
    ) # << BitmaskData( ... )
  for entry in node:
    entry.checkKnownKeys(BitmaskValueData, [ "comment", "bitpos", "name", "protect", "value", "alias", "api", "deprecated" ])
    if entry.tag() == "comment" : continue  # Infix Comment, inbetween enum fields
    # Add EnumValue alias to the registry and skip to the next entry
    if entry.attr("alias") != "":
      parser.registry.bitmaskAliases[ entry.attr("alias") ] = AliasData(
        name       : entry.attr("name"),
        deprecated : entry.attr("deprecated"),
        api        : entry.attr("api"),
        xmlLine    : entry.lineNumber )
      continue
    # Normal BitmasValue entry
    elif data.values.containsOrIncl( entry.attr("name"), BitmaskValueData(
      isValue  : entry.attr("value") != "",
      value    : entry.attr("value"),
      comment  : entry.attr("comment"),
      bitpos   : entry.attr("bitpos"),
      protect  : entry.attr("protect"),
      xmlLine  : entry.lineNumber,
      )): duplicateAddError("Bitmask field",entry.attr("name"),entry.lineNumber)
  if parser.registry.bitmasks.containsOrIncl( node.attr("name"), data):
    duplicateAddError("Bitmask",node.attr("name"),node.lineNumber)

proc addNormalEnum *(parser :var Parser; node :XmlNode) :void=
  ## Treats the given node as a normal enum, and adds its contents to the respective generator registry field.
  node.checkKnownKeys(EnumData, [ "comment", "unused", "type", "name" ])
  var data = EnumData(
    comment   : node.attr("comment"),
    xmlLine   : node.lineNumber,
    ) # << EnumData( .. )
  for entry in node:
    entry.checkKnownKeys(EnumValueData, [ "comment", "value", "protect", "name", "alias", "deprecated", "start", "api" ])
    if   entry.tag() == "comment" : continue  # Infix Comment, inbetween enum fields
    elif entry.tag() == "unused"  : data.unused = entry.attr("start")
    # Add EnumValue alias to the registry and skip to the next entry
    if entry.attr("alias") != "":
      parser.registry.enumAliases[ entry.attr("alias") ] = AliasData(
        name       : entry.attr("name"),
        deprecated : entry.attr("deprecated"),
        api        : entry.attr("api"),
        xmlLine    : entry.lineNumber )
      continue
    # Normal EnumValue entry
    elif data.values.containsOrIncl( entry.attr("name"), EnumValueData(
      comment  : entry.attr("comment"),
      value    : entry.attr("value"),
      protect  : entry.attr("protect"),
      xmlLine  : entry.lineNumber,
      )): duplicateAddError("Enum field",entry.attr("name"),entry.lineNumber)
  if parser.registry.enums.containsOrIncl( node.attr("name"), data):
    duplicateAddError("Enum",node.attr("name"),node.lineNumber)

proc readEnum *(parser :var Parser; node :XmlNode) :void=
  ## Treats the given node as an enum block, and adds its contents to the respective generator registry field.
  # Add constants, alias or bitmasks, and return early
  if   node.attr("name")  == "API Constants" : parser.addConsts(node)     ; return
  elif node.attr("type")  == "bitmask"       : parser.addBitmask(node)    ; return
  elif node.attr("type")  == "enum"          : parser.addNormalEnum(node) ; return
  elif node.attr("name")  == ""              : unreachable "readEnum->node.attr() section. The enum name should never be empty."
  else:unreachable &"addEnum->node.attr() section. else case. Failing XmlNode contains: \n\n{$node}\n\n"
