# Generator dependencies
import ./common


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
# Templates
const ConstHeader      = "## API Constants\n"
const ConstTempl       = "const {name.symbolToNim} *:{entry.getType}= {entry.getValue()}\n"
const ConstAliasHeader = "## API Constant Aliases\n"
const ConstAliasTempl  = "const {alias.name.symbolToNim} *:{entry.getType}{alias.getDeprecated(name)}= {name.symbolToNim}\n"
const EnumHeader       = "## Value Enums\n"
const GenTempl         = """
{VulkanNimHeader}
import std/sets

{enums}
"""
#_____________________________
# Tools
func getType  (data :ConstantData) :string=  data.typ.cTypeToNim()
func getValue (data :ConstantData) :string=  data.value.cValueToNim()


#_______________________________________
# Codegen Entry Point
#_____________________________
proc generateEnums *(gen: Generator) :void=
  # Configuration
  let outputDir = fmt"./src/VulkanNim/{gen.api}_enums.nim"
  var enums :string  # Output string

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
  # Codegen Enum
  # TODO: Enum reordering for negative values
  enums.add EnumHeader
  for name in gen.registry.enums.keys():
    var tmp :string
    tmp.add &"type {name} * = enum\n"
    for field in gen.registry.enums[name].values.keys():
      if field == "": continue
      let val = gen.registry.enums[name].values[field].value
      let cmt = if gen.registry.enums[name].values[field].comment == "": "" else:
        &"  ## {gen.registry.enums[name].values[field].comment}"
      tmp.add &"  {field} = {val}{cmt}\n"
    enums.add &"{tmp}\n"

  #_______________________________________
  # Codegen EnumAliases


  #_______________________________________
  # Write the enums to the output file
  writeFile(outputDir, fmt GenTempl)

##[ TODO ]#
type EnumValueData * = object
  ## Represents the IR data for a single field in a Vulkan Enum set
  comment  *:string
  value    *:string
  protect  *:string  # Only enum values added by the Extensions section have this field active. Not in the main list.
  xmlLine  *:int

type EnumData * = object
  ## Represents the IR data for a Vulkan Enum set, and all of its contained fields.
  comment  *:string
  values   *:OrderedTable[string, EnumValueData]
  unused   *:string
  xmlLine  *:int
]##
