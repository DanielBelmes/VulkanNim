# Generator dependencies
import ./common

const genTemplate = """
{VulkanNimHeader}

## Vulkan Formats
{formats}
"""
proc generateFormats *(gen :Generator; C_like :static bool= true) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_formats.nim"
  var formats :string
  writeFile(outputDir,fmt genTemplate)

