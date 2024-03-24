# Generator dependencies
import ../common

const genTemplate = """
{VulkanNimHeader}

## Vulkan Extension Inspection
{extensions}
"""

proc generateExtensionInspection *(gen :Generator; C_like :static bool= true) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_extension_inspection.nim"
  var extensions :string
  writeFile(outputDir,fmt genTemplate)


