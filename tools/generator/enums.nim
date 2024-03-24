# std dependencies
import std/strformat
# Generator dependencies
import ../common

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

