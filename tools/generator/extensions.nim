# Generator dependencies
import ./base

const genTemplate = """
{VulkanNimHeader}

## Vulkan Extension Inspection
{extensions}
"""

const extensionConstTemplate = "const {name}* = {value}\n"


proc genExtensionEnumConstants(extensions: OrderedTable[string, ExtensionData]): string =
  for extensionName, extensionData in extensions:
    for requireData in extensionData.requireData:
      for constData in requireData.enums:
        if constData.value != "" and constData.extends == "":
          let name = constData.name
          let value = constData.value
          result &= fmt(extensionConstTemplate)


proc generateExtensionInspection *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_extension_inspection.nim"
  let extensions :string = genExtensionEnumConstants(gen.registry.extensions)
  writeFile(outputDir,fmt genTemplate)


