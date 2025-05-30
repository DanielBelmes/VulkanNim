import ../parser/base; export base
import std/options

const VulkanNimHeader * = """
# AutoGenerated File
# TODO: Add VulkanNim Header here"""

type Generator * = object
  api      *:string  ## needs to be of value "vulkan" or "vulkansc"
  registry *:Registry
  #C_like *: bool


#_______________________________________
# Generator Tools used by all modules
#___________________
func getDeprecated *(data :AliasData; name :string) :string=
  ## Returns a {.deprecated: reason.} pragma string, based on the information contained in the given AliasData
  if data.deprecated == "": return ""
  var reason :string= case data.deprecated:
  of "aliased":  &"{data.deprecated}:  {name}  has been aliased to  {data.name}"
  else: raise newException(CodegenError, &"Tried to add codegen for a deprecated alias, but it contains an unknown reason:\n └─> {data.deprecated}\n")
  result = &" {{.deprecated: \"{reason}\".}}"

proc isTypeFromExtension*(extensions: OrderedTable[string, ExtensionData], name: string) : bool =
  for ext in extensions.values:
    for requireData in ext.requireData:
      for typeName in requireData.types.keys():
        if typeName == name:
          return true

proc isTypeFromFeature*(api: string, features: seq[FeatureData], name: string): bool =
  for feat in features:
    if not feat.api.contains(api): continue
    for requireData in feat.requireData:
      for typeName in requireData.types:
        if typeName == name:
          result = true

proc getAlias*(aliases: OrderedTable[string, AliasData], searchValue: string): Option[string] =
  for name, alias in aliases.pairs:
    if(alias.name == searchValue): return some(name)
