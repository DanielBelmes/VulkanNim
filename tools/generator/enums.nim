# std dependencies
import std/strformat
import std/strutils
import ../customxmlParsing/xmltree
import std/strtabs
import std/sets
# Generator dependencies
import ../helpers
import ./common
import ./license


const genTemplate = """
{VulkanNimHeader}
import std/sets

{enums}
"""
##[
]##

proc addConsts *(gen :var Generator; node :XmlNode) :void=
  ## Treats the given node as a constants block, and adds its contents to the generator registry.
  for entry in node:
    if gen.registry.constants.containsOrIncl(entry.attr("name"), ConstantData(
      typ     : entry.attr("type"),
      value   : entry.attr("value"),
      xmlLine : entry.lineNumber,
      )): duplicateAdd("Enum constant",entry.attr("name"),entry.lineNumber)

proc addAlias *(gen :var Generator; node :XmlNode) :void=  discard
  ## Treats the given node as an alias, and adds its contents to the respective generator registry field.

proc addBitmask *(gen :var Generator; node :XmlNode) :void=  discard
  ## Treats the given node as a bitmask enum, and adds its contents to the respective generator registry field.

proc addNormalEnum *(gen :var Generator; node :XmlNode) :void=
  ## Treats the given node as a normal enum, and adds its contents to the respective generator registry field.
  # Add normal enum
  var data = EnumData(
    bitwidth  : node.attr("bitwidth"),
    isBitmask : node.attr("type") == "bitmask",
    xmlLine   : node.lineNumber,
    ) # << EnumData( .. )
  for entry in node:
    if entry.tag() == "comment": continue  # Infix Comment, inbetween enum fields
    if data.values.containsOrIncl( entry.attr("name"), EnumValueData(
      alias    : entry.attr("alias"),
      bitpos   : entry.attr("bitpos"),
      name     : entry.attr("name"),
      protect  : entry.attr("protect"),
      value    : entry.attr("value"),
      xmlLine  : entry.lineNumber,
      )):
      duplicateAdd("Enum field",entry.attr("name"),entry.lineNumber)
  # for name,field in data.fieldPairs:
  #   echo "______________________________"
  #   echo name," : ",field,"\n"


proc readEnum *(gen :var Generator; node :XmlNode) :void=
  ## Treats the given node as an enum block, and adds its contents to the respective generator registry field.
  # Add constants, alias or bitmasks, and return early
  if   node.attr("name")  == "API Constants" : gen.addConsts(node)     ; return
  elif node.attr("alias") != ""              : gen.addAlias(node)      ; return
  elif node.attr("type")  == "bitmask"       : gen.addBitmask(node)    ; return
  elif node.attr("type")  == "enum"          : gen.addNormalEnum(node) ; return
  elif node.attr("name")  == ""              : unreachable "readEnum->node.attr() section. The enum name should never be empty."
  else:unreachable &"addEnum->node.attr() section. else case. Failing XmlNode contains: \n\n{$node}\n\n"

##[ TODO
type AliasData* = object
  name     *:string
  xmlLine  *:int
type BitmaskData* = object
  require  *:string
  `type`   *:string
  xmlLine  *:int

type EnumValueData* = object
  alias    *:string
  bitpos   *:string
  name     *:string
  protect  *:string
  value    *:string
  xmlLine  *:int
type EnumData* = object
  # bitwidth          *:string
  # isBitmask         *:bool = false
  unsupportedValues *:seq[EnumValueData]
  values            *:OrderedTable[string, EnumValueData]
  # xmlLine           *:int
type Registry * = object
  constantAliases *:OrderedTable[string, AliasData]
  constants       *:OrderedTable[string, ConstantData]
  bitmaskAliases  *:OrderedTable[string, AliasData]
  bitmasks        *:OrderedTable[string, BitmaskData]
  enumAliases     *:OrderedTable[string, AliasData]
  enums           *:OrderedTable[string, EnumData]
]##

proc generateEnumFile *(gen: Generator) :void=
  # Configuration
  let outputDir = fmt"./src/VulkanNim/{gen.api}_enums.nim"
  var enums :string  # Output string
  # Generation subprocs
  proc genEnum (node :XmlNode) :string=
    let name  = node.attr("name")
    if name == "API Constants": return ""
    let bits  = node.attr("type") == "bitmask"
    let typ   = if bits: &"set[{name.replace(\"Bits\", \"Bit\")}]" else: "enum"
    let width = node.attr("bitwidth")
    let pure  = if bits: " " elif width != "": "{.pure, size: $1.}" % [width] else: "{.pure.}"
    result    = "type $1 *$2= $3\n" % [name, pure, typ]
    for key,val in node.attrs().pairs:
      case key
      of "type": discard
      of "name": discard
      else: discard #echo key, " ", val
  # Find the enums
  for node in gen.doc.findElems("enums"):
    enums.add node.genEnum()
  # Write the enums to the output file
  writeFile(outputDir, fmt genTemplate)

