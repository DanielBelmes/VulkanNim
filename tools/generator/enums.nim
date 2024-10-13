# std dependencies
import std/strformat
# Generator dependencies
import ./base

#_________________________________________________
# Codegen
#_______________________________________
# Tools
func getType  *(data :ConstantData) :string=  data.typ.cTypeToNim()
func getValue *(data :ConstantData) :string=  data.value.cValueToNim()
#_____________________________
# Templates: Consts
const ConstHeader       = "## API Constants\n"
#const ConstTempl        = "const {name.symbolToNim} *:{entry.getType}= {entry.getValue()}\n"
const ConstTempl       = "const {name} *:{entry.getType}= {entry.getValue()}\n"
const ConstAliasHeader  = "## API Constant Aliases\n"
#const ConstAliasTempl   = "const {alias.name.symbolToNim} *:{entry.getType()}{dep}= {name.symbolToNim}\n"
const ConstAliasTempl  = "const {alias.name} *:{entry.getType()}{dep}= {name}\n"
const ConstGenTempl     = """
{VulkanNimHeader}

{consts}
"""
#_____________________________
# Templates: Enums
#const EnumTitleTempl    = "type {name.symbolToNim} * = enum\n"
const EnumTitleTempl   = "type {name} * = enum\n"
#const EnumFieldTempl    = "  {field.symbolToNim} = {val}{cmt}\n"
const EnumFieldTempl   = "  {symbolToNim(field)} = {val}{cmt}\n"
const EnumFieldCmtTempl = "  ## {gen.registry.enums[name].values[field].comment}"  # without \n, its added by EnumFieldTempl
const EnumAliasHeader  = "## API Enum Aliases\n"
const EnumAliasTempl  = "type {name}* {dep}= {alias.name}\n"
const EnumHeader        = "## Value Enums\n"
const EnumGenTempl      = """
{VulkanNimHeader}
import std/sets

{enums}
"""
const BitmaskHeader        = "## Value Bitmasks\n"
const BitMaskFieldTempl   = "  {symbolToNim(field)} = {val}{cmt}\n"
const BitmaskFieldCmtTempl = "  ## {gen.registry.bitmasks[name].values[field].comment}"  # without \n, its added by EnumFieldTempl
const BitmaskAliasHeader  = "## API Bitmask Aliases\n"
#_____________________________
# Templates: Bitmasks


func enumCmp *(A,B :(string, EnumValueData | BitmaskValueData)) :int=
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


#_______________________________________
proc generateEnums *(gen: Generator) :void= # TODO need to exclude extensions
  # Configuration
  let outputDir = fmt"./src/VulkanNim/{gen.api}_enums.nim"
  var enums :string  # Output string

  #_____________________________
  # Codegen Enum
  # TODO: Enum reordering for negative values
  enums.add EnumHeader
  for name in gen.registry.enums.keys():
    var tmp :string
    tmp.add(fmt EnumTitleTempl )
    var ordered = gen.registry.enums[name].values
    ordered.sort( enumCmp )
    for field in ordered.keys():
      if field == "": continue
      let val = gen.registry.enums[name].values[field].value
      let cmt = if gen.registry.enums[name].values[field].comment == "": "" else: fmt EnumFieldCmtTempl
      tmp.add(fmt EnumFieldTempl )
    enums.add &"{tmp}\n"

  #_____________________________
  # Codegen EnumAliases
  # TODO redo Enum alias
  # enums.add EnumAliasHeader
  # for name in gen.registry.enumAliases.keys():
  #     let alias = gen.registry.enumAliases[name]
  #     let dep   = alias.getDeprecated(name)
  #     if not gen.registry.enums.hasKey(alias.name):
  #       continue
  #     if gen.registry.enums[alias.name].values.len < 0:
  #       continue
  #     enums.add(fmt EnumAliasTempl)

  #_____________________________
  # Bitmask Enum
  enums.add BitmaskHeader
  for name in gen.registry.bitmasks.keys():
    var tmp :string
    tmp.add(fmt EnumTitleTempl )
    var ordered = gen.registry.bitmasks[name].values
    # @todo order bitmasks!!!!
    if(ordered.len == 0): continue
    ordered.sort( enumCmp )
    for field in ordered.keys():
      if field == "": continue
      let val = gen.registry.bitmasks[name].values[field].value
      let cmt = if gen.registry.bitmasks[name].values[field].comment == "": "" else: fmt BitmaskFieldCmtTempl
      tmp.add(fmt BitMaskFieldTempl )
    enums.add &"{tmp}\n"

  #_____________________________
  # Codegen EnumAliases
  # enums.add BitmaskAliasHeader
  # for name in gen.registry.bitmaskAliases.keys():
  #     let alias = gen.registry.bitmaskAliases[name]
  #     let dep   = alias.getDeprecated(name)
  #     if not gen.registry.bitmasks.hasKey(alias.name):
  #       continue
  #     enums.add(fmt EnumAliasTempl)



  #_____________________________
  # Write the enums to the output file
  writeFile(outputDir, fmt EnumGenTempl)

#_______________________________________
# Codegen Entry Point
#_____________________________
proc generateConsts *(gen: Generator) :void=
  # Configuration
  let outputDir = fmt"./src/VulkanNim/{gen.api}_consts.nim"
  var consts :string  # Output string

  #_____________________________
  # Codegen Constants
  consts.add ConstHeader
  for name in gen.registry.constants.keys():
    let entry = gen.registry.constants[name]
    consts.add(fmt ConstTempl)
  consts.add "\n"

  #_____________________________
  # Codegen Constant Aliases
  # TODO redo const alias
  # consts.add ConstAliasHeader
  # for name in gen.registry.constantAliases.keys():
  #   let entry = gen.registry.constants[name]
  #   let alias = gen.registry.constantAliases[name]
  #   let dep   = alias.getDeprecated(name)
  #   consts.add(fmt ConstAliasTempl)

  #_____________________________
  # Write the consts to the output file
  writeFile(outputDir, fmt ConstGenTempl)