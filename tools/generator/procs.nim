# std dependencies
import std/strscans
# Generator dependencies
import ./base


const genTemplate = """
{VulkanNimHeader}
import ./dynamic

## Vulkan Procedures
{procs}
"""

const procTemplate = "proc {name}*({args}): {returnType} {{.cdecl, importc, dynlib: vkDLL.}}"

proc generateProc(`proc`: CommandData): string =
  let name: string = toNimSafeIdentifier(`proc`.proto.name)
  let returnType: string = c2NimType(`proc`.proto.typ)
  var args: string = ""
  let paramLen = `proc`.params.len-1
  for index, arg in `proc`.params:
    var prefix = ""
    if arg.typ.postfix == "*":
      prefix = "ptr "
    elif arg.typ.postfix == "**":
      prefix = "ptr ptr "
    args &= fmt"{toNimSafeIdentifier(arg.typ.name)}: {prefix}{c2NimType(arg.typ.typ)}"
    if index < paramLen:
      args &= ", "
  return fmt(procTemplate)

proc generateProcs *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_procs.nim"
  var procs :string = ""
  for `proc` in gen.registry.commands:
    if(`proc`.alias != ""): continue
    procs &= generateProc(`proc`)
    procs &= '\n'
  writeFile(outputDir,fmt genTemplate)

