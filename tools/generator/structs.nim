# Generator dependencies
import ./base
import std/strutils

const genTemplate = """
{VulkanNimHeader}
import ./vulkan_consts
import ./vulkan_enums
import ./vulkan_types
import ./vulkan_handles

## Vulkan Structs
{structs}
"""

const memberTemplate = "  {memberName}*: {prefix}{`type`}\n"

const structTemplate = """
type {name}* {isUnion} = object
{members}
"""

proc generateStruct *(name: string, struct :StructureData) :string=
  if(name == "VkClearColorValue"): echo struct
  var members :string = ""
  let isUnion :string = if(struct.isUnion): "{.union.}" else: ""
  for member in struct.members: #len?, Optional?, values
    let memberName = toNimSafeIdentifier(member.name)
    let stars = if(member.`type`.`type` == "void"): 0 else: member.`type`.postfix.count('*') #might have const but we won't deal with that for now
    let prefix = "ptr ".repeat(stars) #This is sick. will be empty string if 0
    let safeType = if(member.`type`.`type` == "void"): "pointer" else: c2NimType(member.`type`.`type`)
    let `type` = if(member.arraySizes.len() > 0): fmt"array[{member.arraySizes[0]}, {safeType}]" else: safeType #TODO look up enum array sizes
    members &= fmt memberTemplate
  return fmt structTemplate #returnedOnly?, structextends?

proc generateStructs *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_structs.nim"
  var structs :string = ""
  let structMap = gen.registry.structs
  for name in structMap.keys():
    structs &= generateStruct(toNimSafeIdentifier(name), structMap[name])
    structs &= '\n'
  writeFile(outputDir,fmt genTemplate)

