# std dependencies
import std/strformat
import std/strutils
import std/xmlparser
import std/xmltree
import std/strtabs
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
      else: echo key, " ", val
  # Find the enums
  for node in gen.doc.findElems("enums"):
    enums.add node.genEnum()
  # Write the enums to the output file
  writeFile(outputDir, fmt genTemplate)
