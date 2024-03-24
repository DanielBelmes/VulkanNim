# std dependencies
import std/strformat
# Generator dependencies
import ../common


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

#_________________________________________________
# Codegen
#_______________________________________
# Tools
func getType  *(data :ConstantData) :string=  data.typ.cTypeToNim()
func getValue *(data :ConstantData) :string=  data.value.cValueToNim()
#_____________________________
# Templates: Consts
const ConstHeader       = "## API Constants\n"
const ConstTempl        = "const {name.symbolToNim} *:{entry.getType}= {entry.getValue()}\n"
const ConstTemplC       = "const {name} *:{entry.getType}= {entry.getValue()}\n"
const ConstAliasHeader  = "## API Constant Aliases\n"
const ConstAliasTempl   = "const {alias.name.symbolToNim} *:{entry.getType()}{dep}= {name.symbolToNim}\n"
const ConstAliasTemplC  = "const {alias.name} *:{entry.getType()}{dep}= {name}\n"
const ConstGenTempl     = """
{VulkanNimHeader}

{consts}
"""
#_____________________________
# Templates: Enums
const EnumTitleTempl    = "type {name.symbolToNim} * = enum\n"
const EnumTitleTemplC   = "type {name} * = enum\n"
const EnumFieldTempl    = "  {field.symbolToNim} = {val}{cmt}\n"
const EnumFieldTemplC   = "  {field} = {val}{cmt}\n"
const EnumFieldCmtTempl = "  ## {gen.registry.enums[name].values[field].comment}"  # without \n, its added by EnumFieldTempl
const EnumHeader        = "## Value Enums\n"
const EnumGenTempl      = """
{VulkanNimHeader}
import std/sets

{enums}
"""
#_____________________________
# Templates: Bitmasks

#_______________________________________
# Codegen Entry Point
#_____________________________
proc generateConsts *(gen: Generator; C_like :static bool= true) :void=
  # Configuration
  let outputDir = fmt"./src/VulkanNim/{gen.api}_consts.nim"
  var consts :string  # Output string

  #_____________________________
  # Codegen Constants
  consts.add ConstHeader
  for name in gen.registry.constants.keys():
    let entry = gen.registry.constants[name]
    consts.add(
      when C_like : fmt ConstTemplC
      else        : fmt ConstTempl      )
  consts.add "\n"

  #_____________________________
  # Codegen Constant Aliases
  consts.add ConstAliasHeader
  for name in gen.registry.constantAliases.keys():
    let entry = gen.registry.constants[name]
    let alias = gen.registry.constantAliases[name]
    let dep   = alias.getDeprecated(name)
    consts.add(
      when C_like : fmt ConstAliasTemplC
      else        : fmt ConstAliasTempl      )

  #_____________________________
  # Write the consts to the output file
  writeFile(outputDir, fmt ConstGenTempl)


func enumCmp *(A,B :(string, EnumValueData)) :int=
  ## Compares two EnumValueData entries of a EnumData table.
  ## Same as system.cmp(a,b), but helps nim understand the special cases of values sent by the Vulkan spec
  let a = A[1].value
  let b = B[1].value
  if   a.len == 0 and b.len != 0                 : -1
  elif a.len != 0 and b.len == 0                 :  1
  elif a.startsWith("0x") and b.startsWith("0x") : cmp( a.parseHexInt() , b.parseHexInt() )
  elif b.startsWith("0x")                        : cmp( a.parseInt()    , b.parseHexInt() )
  elif a.startsWith("0x")                        : cmp( a.parseHexInt() , b.parseInt()    )
  else                                           : cmp( a.parseInt()    , b.parseInt()    )
