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


#_______________________________________
proc generateEnums *(gen: Generator; C_like :static bool= true) :void=
  # Configuration
  let outputDir = fmt"./src/VulkanNim/{gen.api}_enums.nim"
  var enums :string  # Output string

  #_____________________________
  # Codegen Enum
  # TODO: Enum reordering for negative values
  enums.add EnumHeader
  for name in gen.registry.enums.keys():
    var tmp :string
    tmp.add( when C_like: fmt EnumTitleTemplC else: EnumTitleTempl )
    var ordered = gen.registry.enums[name].values
    ordered.sort( enumCmp )
    for field in ordered.keys():
      if field == "": continue
      let val = gen.registry.enums[name].values[field].value
      let cmt = if gen.registry.enums[name].values[field].comment == "": "" else: fmt EnumFieldCmtTempl
      tmp.add( when C_like: fmt EnumFieldTemplC else: EnumFieldTempl )
    enums.add &"{tmp}\n"

  #_____________________________
  # Codegen EnumAliases


  #_____________________________
  # Write the enums to the output file
  writeFile(outputDir, fmt EnumGenTempl)

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