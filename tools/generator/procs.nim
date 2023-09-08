# Generator dependencies
import ./common


proc readProcs *(gen :var Generator; node :XmlNode) :void=
  ## Treats the given node as a procs block, and adds its contents to the generator registry.
  ## Vulkan procs are called commands in the spec.
  # for entry in node.children():
  discard


const genTemplate = """
{VulkanNimHeader}

## Vulkan Procedures
{procs}
"""

proc generateProcs *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_procs.nim"
  var procs :string
  writeFile(outputDir,fmt genTemplate)

