# Generator dependencies
import ./base

const genTemplate = """
{VulkanNimHeader}

## Vulkan Formats
{formats}
"""
proc generateFormats *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_formats.nim"
  var formats :string
  writeFile(outputDir,fmt genTemplate)

