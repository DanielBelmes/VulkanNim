# Generator dependencies
import ./base
import std/strutils

const genTemplate = """
{VulkanNimHeader}

## Vulkan Structs
{structs}
"""

const memberTemplate = "  {memberName}*: {prefix}{`type`}{value}\n"

const structTemplate = """
type {name}* {isUnion}= object
{members}
"""

proc generateStruct *(api: string, name: string, struct :StructureData, types: OrderedTable[string, TypeData]) :string=
  var members :string = ""
  let isUnion :string = if(struct.isUnion): "{.union.} " else: ""
  for member in struct.members: #len?, Optional?, values
    if not types.contains(member.`type`.`type`):
      if not basicCType(member.`type`.`type`):
        raise newException(CodegenError, &"Struct: {name} Struct Member:{member.name} with Type: {member.`type`.`type`} not in registry.\n")
    if member.api != "" and member.api != api: continue
    let memberName = toNimSafeIdentifier(member.name)
    let stars = if(member.`type`.`type` == "void"): 0 else: member.`type`.postfix.count('*') #might have const but we won't deal with that for now
    let prefix = "ptr ".repeat(stars) #This is sick. will be empty string if 0
    let safeType = if(member.`type`.`type` == "void"): "pointer" else: toNimSafeIdentifier(c2NimType(member.`type`.`type`))
    let `type` = if(member.arraySizes.len() > 0): fmt"array[{member.arraySizes[0]}, {safeType}]" else: safeType #TODO look up enum array sizes
    let value = if(member.value != ""): " = " & symbolToNim(member.value) else: ""
    members &= fmt memberTemplate
  return fmt structTemplate #returnedOnly?, structextends?

proc generateStructs *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_structs.nim"
  var structs :string = ""
  let structMap = gen.registry.structs
  let types = gen.registry.types
  for name in structMap.keys():
    # let alias = getAlias(gen.registry.structAliases, name)
    # if alias.isSome():
    #   if isTypeFromExtension(gen.registry.extensions, alias.get()): continue
    #   if not isTypeFromFeature(gen.api, gen.registry.features, alias.get()): continue
    # if isTypeFromExtension(gen.registry.extensions, name): continue
    # if not isTypeFromFeature(gen.api, gen.registry.features, name): continue
    structs &= generateStruct(gen.api, toNimSafeIdentifier(name), structMap[name], types)
    structs &= '\n'
  writeFile(outputDir,fmt genTemplate)

