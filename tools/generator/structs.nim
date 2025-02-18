# Generator dependencies
import ./base
import std/strutils

const genTemplate = """
{VulkanNimHeader}

## Vulkan Structs
{structs}

## Vulkan Struct Alias
{structAliases}
"""

const memberTemplate = "  {memberName}*: {`type`}{value}\n"

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
    let safeType = if(member.`type`.`type` == "void"): "pointer" else: c2NimType(toNimSafeIdentifier(member.`type`.`type`),member.`type`.postfix.count("*"))
    let `type` = if(member.arraySizes.len() > 0): fmt"array[{member.arraySizes[0]}, {safeType}]" else: safeType #TODO look up enum array sizes
    let value = if(member.value != ""): " = " & symbolToNim(member.value) else: ""
    members &= fmt memberTemplate
  return fmt structTemplate #returnedOnly?, structextends?

proc generateStructAlias *(api: string, name: string, aliasData :AliasData) :string=
  return fmt"type {name}* = {aliasData.name}" & "\n"

proc generateStructs *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_structs.nim"
  var structs :string = ""
  var structAliases: string = ""
  let structMap = gen.registry.structs
  let types = gen.registry.types
  for name in structMap.keys():
    structs &= generateStruct(gen.api, toNimSafeIdentifier(name), structMap[name], types)
    structs &= '\n'
  for name, aliasData  in gen.registry.structAliases:
    structAliases &= generateStructAlias(gen.api, toNimSafeIdentifier(name), aliasData)
  writeFile(outputDir,fmt genTemplate)

