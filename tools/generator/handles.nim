# Generator dependencies
import ./base
const genTemplate = """
#[
=====================================

Handles

=====================================
]#

type
  VkHandle* = int64
  VkNonDispatchableHandle* = int64

{handles}
"""
const handleTemplate = "type {handle}* = distinct {`type`}\n"

proc generateHandles *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_handles.nim"
  var handles :string = ""
  let handleMap = gen.registry.handles
  for handle in handleMap.keys():
    let `type` = if handleMap[handle].isDispatchable: "VkHandle" else: "VkNonDispatchableHandle"
    handles &= fmt handleTemplate
  writeFile(outputDir,fmt genTemplate)

