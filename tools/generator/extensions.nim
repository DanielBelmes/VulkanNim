# Generator dependencies
import ./base

const genTemplate = """
{VulkanNimHeader}

## Vulkan Extension Inspection
{extensions}
"""

proc generateExtensionInspection *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_extension_inspection.nim"
  var extensions :string
  writeFile(outputDir,fmt genTemplate)


