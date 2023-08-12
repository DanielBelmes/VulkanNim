# std dependencies
import std/strformat
import std/strutils
import std/xmlparser
import std/xmltree
import std/strtabs
import std/sets
# Generator dependencies
import ../helpers
import ./common


const genTemplate = """
{LicensePlate}
#[
=====================================

Enums

=====================================
]#

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
      xmlLine : -1,
      )): raise newException(ParsingError, &"Tried to add a constant that already exists inside the generator : {entry.attr(\"name\")}")
  echo gen.registry.constants

proc addEnum *(gen :var Generator; node :XmlNode) :void=
  ## Treats the given node as an enum block, and adds its contents to the respective generator registry field.
  # Add constants
  if node.attr("name") == "API Constants": gen.addConsts(node); return
  # Add enum or bitmask
  var data = EnumData(
    bitwidth  : node.attr("bitwidth"),
    isBitmask : node.attr("type") == "bitmask",
    xmlLine   : -1,
    ) # << EnumData( .. )
  for key,val in node.attrs().pairs:
    if   key == "type":     continue
    elif key == "enum":     continue
    elif key == "name":     continue
    elif key == "bitwidth": continue
    elif key == "comment":  continue
    else: echo "attr: ",key, " ", val
  echo "_____________________________"
  for entry in node:
    for key,val in entry.attrs().pairs:
      if key == "type" and val == "float": echo "Float enum @: ",entry.attr("name")
      if   key == "name":    continue
      elif key == "value":   continue
      elif key == "comment": continue
      elif key == "alias":   continue
      echo key, " : ", val
    let field = EnumValueData(
      alias    : entry.attr("alias"),
      bitpos   : "",
      name     : entry.attr("name"),
      protect  : "",
      value    : entry.attr("value"),
      xmlLine  : -1,
      )
    # echo field
  # echo data

##[ TODO
type AliasData* = object
  name     *:string
  xmlLine  *:int
# type ConstantData* = object
#   name     *:string
#   typ`     *:string
#   value    *:string
#   xmlLine  *:int
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
  values            *:OrderedSet[EnumValueData]
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

