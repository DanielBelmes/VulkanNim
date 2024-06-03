# Generator dependencies
import ./base

const genTemplate = """
{VulkanNimHeader}
Not Super important by itself as it's coverd by enum. However format memory map info in vk.xml can be turned into some useful functions https://github.com/KhronosGroup/Vulkan-Headers/blob/main/include/vulkan/vulkan_format_traits.hpp

## Vulkan Formats
{formats}
"""
proc generateFormats *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_formats.nim"
  var formats :string
  writeFile(outputDir,fmt genTemplate)

