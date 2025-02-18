# Generator dependencies
import ./base

const genTemplate = """
#[
=====================================

Types

=====================================
]#

# defines
{defines}

# Base types
{baseTypes}

# Bitmasks
{bitmasks}

# Requires
{requires}
"""

const funcPointersTemplate = """
#[
=====================================

Types

=====================================
]#

#Function Pointers
{funcpointers}
"""

proc genDefines(name: string) : string =
  case name
    of "VK_MAKE_VERSION":
      result = """
template vkMakeVersion*(major, minor, patch: untyped): untyped =
  (((major) shl 22) or ((minor) shl 12) or (patch))
"""
    of "VK_VERSION_MAJOR":
      result = """
template vkVersionMajor*(version: untyped): untyped =
  ((uint32)(version) shr 22)
"""
    of "VK_VERSION_MINOR":
      result = """
template vkVersionMinor*(version: untyped): untyped =
  (((uint32)(version) shr 12) and 0x000003FF)
"""
    of "VK_VERSION_PATCH":
      result = """
template vkVersionPatch*(version: untyped): untyped =
  ((uint32)(version) and 0x00000FFF)
"""
    of "VK_MAKE_API_VERSION":
      result = """
template vkMakeApiVersion*(variant, major, minor, patch: untyped): untyped =
  (((variant) shl 29) or ((major) shl 22) or ((minor) shl 12) or (patch))
"""
    of "VK_API_VERSION_VARIANT":
      result = """
template vkApiVersionVariant*(version: untyped): untyped =
  ((uint32)(version) shr 29)
"""
    of "VK_API_VERSION_MAJOR":
      result = """
template vkApiVersionMajor*(version: untyped): untyped =
  (((uint32)(version) shr 22) and 0x000007FU)
"""
    of "VK_API_VERSION_MINOR":
      result = """
template vkApiVersionMinor*(version: untyped): untyped =
  (((uint32)(version) shr 12) and 0x000003FF)
"""
    of "VK_API_VERSION_PATCH":
      result = """
template vkApiVersionPatch*(version: untyped): untyped =
  ((uint32)(version) and 0x00000FFF)
"""
    of "VKSC_API_VARIANT":
      result = """
const VKSC_API_VARIANT* = 1
"""
    of "VK_API_VERSION":
      result = """
const VK_API_VERSION* = vkMakeApiVersion(0, 1, 0, 0)
"""
    of "VK_API_VERSION_1_0":
      result = """
const VK_API_VERSION_1_0* = vkMakeApiVersion(0, 1, 0, 0)
"""
    of "VK_API_VERSION_1_1":
      result = """
const VK_API_VERSION_1_1* = vkMakeApiVersion(0, 1, 1, 0)
"""
    of "VK_API_VERSION_1_2":
      result = """
const VK_API_VERSION_1_2* = vkMakeApiVersion(0, 1, 2, 0)
"""
    of "VK_API_VERSION_1_3":
      result = """
const VK_API_VERSION_1_3* = vkMakeApiVersion(0, 1, 3, 0)
"""
    of "VKSC_API_VERSION_1_0":
      result = """
const VKSC_API_VERSION_1_0* = vkMakeApiVersion(VKSC_API_VARIANT, 1, 0, 0)
"""
    of "VK_HEADER_VERSION":
      result = """
const VK_HEADER_VERSION* = 281
""" #TODO I can gen this one
    of "VK_HEADER_VERSION_COMPLETE":
      result = """
const VK_HEADER_VERSION_COMPLETE* = vkMakeApiVersion(0, 1, 3, VK_HEADER_VERSION)
"""
    of "VK_DEFINE_HANDLE":
      result = """"""
    of "VK_USE_64_BIT_PTR_DEFINES":
      result = """"""
    of "VK_NULL_HANDLE":
      result = """
const VK_NULL_HANDLE* = 0
"""
    of "VK_DEFINE_NON_DISPATCHABLE_HANDLE":
      result = """"""
    else:
      raise newException(CodegenError, fmt"Could not find #define {name} in internal map")


proc genFuncPointer(name: string, data: FuncPointerData ): string =
  var arguments = ""
  for index, arg in data.arguments:
    arguments &= fmt"{toNimSafeIdentifier(arg.name)}: {c2NimType(arg.`type`, if arg.isPtr: 1 else: 0)}"
    if index < data.arguments.len - 1:
      arguments &= "; "
  return fmt"type {toNimSafeIdentifier(name)}* = proc({arguments}): {c2NimType(data.`type`,0)} {{.cdecl.}}" & '\n'

proc genBaseTypes(name:string, baseType: BaseTypeData): string =
  if baseType.typeinfo.type != "":
    let `type` = c2NimType(baseType.typeinfo.type, baseType.typeinfo.postfix.count("*"))
    return fmt"type {name}* = distinct {`type`}" & "\n"
  else:
    return fmt"type {name}* = ptr object" & "\n"

proc genBitmaskTypes(name:string, bitmask: BitmaskData): string =
  return fmt"type {name}* = distinct {bitmask.typ}" & "\n"

proc genBitmaskAliasTypes(name:string, aliasData: AliasData): string =
  return fmt"type {name}* = {aliasData.name}" & "\n"

proc generateTypes *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_types.nim"
  let funcPointerDir = fmt"./src/VulkanNim/{gen.api}_funcpointers.nim"
  var defines, baseTypes, bitmasks, funcpointers, requires :string = ""
  for `type` in gen.registry.types.keys():
    case gen.registry.types[`type`].category
      of TypeCategory.Bitmask:
        if(gen.registry.bitmaskAliases.contains(`type`)):
          bitmasks &= genBitmaskAliasTypes(`type`, gen.registry.bitmaskAliases[`type`])
        else:
          bitmasks &= genBitmaskTypes(`type`, gen.registry.bitmasks[`type`])
      of TypeCategory.BaseType: baseTypes &= genBaseTypes(`type`,gen.registry.baseTypes[`type`])
      of TypeCategory.Constant: continue
      of TypeCategory.Define: defines &= genDefines(`type`)
      of TypeCategory.Enum: continue
      of TypeCategory.ExternalType: continue
      of TypeCategory.FuncPointer: 
        # if isTypeFromExtension(gen.registry.extensions, `type`): continue
        # if not isTypeFromFeature(gen.api, gen.registry.features, `type`): continue
        funcpointers &= genFuncPointer(`type`, gen.registry.funcPointers[`type`])
      of TypeCategory.Handle: continue
      of TypeCategory.Include: continue
      of TypeCategory.Struct: continue
      of TypeCategory.Union: continue
      of TypeCategory.Unknown: continue
  for require in gen.registry.externalTypes.keys():
    let entry = gen.registry.externalTypes[require]
    if entry.require == "": continue
    if entry.require == "vk_platform": continue
    requires &= fmt "type {toNimSafeIdentifier(require)}* = ptr object\n"
  writeFile(outputDir,fmt genTemplate)
  writeFile(funcPointerDir,fmt funcPointersTemplate)

