# std dependencies
import std/strformat
import std/strutils
import std/strtabs
import ../customxmlParsing/xmltree
import std/tables
# Generator dependencies
import ../helpers
import ./common
import ./license


const GenTempl = """
{VulkanNimHeader}
import std/sets

{enums}
"""


proc addConsts *(gen :var Generator; node :XmlNode) :void=
  ## Treats the given node as a constants block, and adds its contents to the generator registry.
  for entry in node:
    # Add Constant alias to the registry and skip to the next entry
    if entry.attr("alias") != "":
      gen.registry.constantAliases[ entry.attr("alias") ] = AliasData(
        name       : entry.attr("name"),
        deprecated : entry.attr("deprecated"),
        api        : entry.attr("api"),
        xmlLine    : entry.lineNumber )
    # Normal Constant entry
    elif gen.registry.constants.containsOrIncl(entry.attr("name"), ConstantData(
      typ     : entry.attr("type"),
      value   : entry.attr("value"),
      xmlLine : entry.lineNumber,
      )): duplicateAddError("Enum constant",entry.attr("name"),entry.lineNumber)

proc addBitmask *(gen :var Generator; node :XmlNode) :void=
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
      gen.registry.bitmaskAliases[ entry.attr("alias") ] = AliasData(
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
  if gen.registry.bitmasks.containsOrIncl( node.attr("name"), data):
    duplicateAddError("Bitmask",node.attr("name"),node.lineNumber)

proc addNormalEnum *(gen :var Generator; node :XmlNode) :void=
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
      gen.registry.enumAliases[ entry.attr("alias") ] = AliasData(
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
  if gen.registry.enums.containsOrIncl( node.attr("name"), data):
    duplicateAddError("Enum",node.attr("name"),node.lineNumber)

proc readEnum *(gen :var Generator; node :XmlNode) :void=
  ## Treats the given node as an enum block, and adds its contents to the respective generator registry field.
  # Add constants, alias or bitmasks, and return early
  if   node.attr("name")  == "API Constants" : gen.addConsts(node)     ; return
  elif node.attr("type")  == "bitmask"       : gen.addBitmask(node)    ; return
  elif node.attr("type")  == "enum"          : gen.addNormalEnum(node) ; return
  elif node.attr("name")  == ""              : unreachable "readEnum->node.attr() section. The enum name should never be empty."
  else:unreachable &"addEnum->node.attr() section. else case. Failing XmlNode contains: \n\n{$node}\n\n"

proc generateEnumFile *(gen: Generator) :void=
  # Configuration
  let outputDir = fmt"./src/VulkanNim/{gen.api}_enums.nim"
  var enums :string  # Output string

  #_______________________________________
  # TODO: Move to somewhere else
  #_______________________________________
  func getDeprecated (data :AliasData; name :string) :string=
    if data.deprecated == "": return ""
    var reason :string= case data.deprecated:
    of "aliased":  &"{data.deprecated}:  {name}  has been aliased to  {data.name}"
    else: raise newException(CodegenError, &"Tried to add codegen for a deprecated alias, but it contains an unknown reason:\n └─> {data.deprecated}\n")
    result = &" {{.deprecated: \"{reason}\".}}"
  #_______________________________________
  func cTypeToNim (typ :string) :string=
    case typ
    of "uint32_t" : "uint32"
    of "uint64_t" : "uint64"
    of "float"    : "float32"
    else: raise newException(CodegenError, &"Tried to convert a C type to Nim, but it is not a recognized as a known type:\n{typ}")
  func cValueToNim (val :string) :string=
    if "." in val: return val.replace("F", "'f32")
    case val
    of "(~0U)"   : "not 0'u32"
    of "(~1U)"   : "not 1'u32"
    of "(~2U)"   : "not 2'u32"
    of "(~0ULL)" : "not 0'u64"
    else: val
  #_______________________________________
  func getType (data :ConstantData) :string=  data.typ.cTypeToNim()
  func getValue (data :ConstantData) :string=  data.value.cValueToNim()
  func fromScream (sym :string) :string=
    if sym.startsWith("VK_"): result = sym[3..^1].change(SCREAM_CASE, PascalCase)
  #_______________________________________
  const ConstHeader      = "## API Constants\n"
  const ConstTempl       = "const {name.fromScream} *:{entry.getType}= {entry.getValue()}\n"
  const ConstAliasHeader = "## API Constant Aliases\n"
  const ConstAliasTempl  = "const {alias.name.fromScream} *:{entry.getType}{alias.getDeprecated(name)}= {name.fromScream}\n"

  #_______________________________________
  # Codegen Constants
  enums.add ConstHeader
  for name in gen.registry.constants.keys():
    let entry = gen.registry.constants[name]
    enums.add fmt ConstTempl
  enums.add "\n"

  #_______________________________________
  # Codegen Constant Aliases
  enums.add ConstAliasHeader
  for name in gen.registry.constantAliases.keys():
    let entry = gen.registry.constants[name]
    let alias = gen.registry.constantAliases[name]
    enums.add fmt ConstAliasTempl
  enums.add "\n"

  #_______________________________________
  # Write the enums to the output file
  writeFile(outputDir, fmt GenTempl)

