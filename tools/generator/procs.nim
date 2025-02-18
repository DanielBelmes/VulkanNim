# std dependencies
import std/strscans
# Generator dependencies
import ./base


const genTemplate = """
{VulkanNimHeader}

## Vulkan Procedures
{procs}
"""

const procTemplate = "proc {name}*({args}): {returnType} {{.cdecl, importc, dynlib: vkDLL.}}"

proc generateProc(`proc`: CommandData, api: string): string =
  let name: string = toNimSafeIdentifier(`proc`.proto.name)
  let returnType: string = c2NimType(`proc`.proto.typ)
  var args: string = ""
  let paramLen = `proc`.params.len-1
  for index, arg in `proc`.params:
    echo arg
    if arg.api.len > 0 and api notin arg.api:
      continue
    let typ = if arg.typ.typ == "void" and arg.typ.postfix.len > 0: "pointer" else: c2NimType(toNimSafeIdentifier(arg.typ.typ), arg.typ.postfix.count("*"))
    args &= fmt"{toNimSafeIdentifier(arg.typ.name)}: {typ}"
    if index < paramLen:
      args &= ", "
  return fmt(procTemplate)

proc generateProcs *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_procs.nim"
  var procs :string = ""
  for `proc` in gen.registry.commands:
    procs &= generateProc(`proc`, gen.api)
    procs &= '\n'
  writeFile(outputDir,fmt genTemplate)

