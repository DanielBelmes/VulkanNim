# Generator dependencies
import ./common


proc readProcs *(gen :var Generator; node :XmlNode) :void=
  ## Treats the given node as a procs block, and adds its contents to the generator registry.
  ## Vulkan procs are called commands in the spec.
  if node.tag != "commands": raise newException(ParsingError, &"XML data:\n{$node}\nError when reading commands data from a node that is not known to contain commands:\n  └─> {node.tag}\n")
  node.checkKnownKeys(CommandData, ["comment"])
  # TODO: node.comment
  for entry in node:
    if entry.tag != "command": raise newException(ParsingError, &"XML data:\n{$entry}\nError when reading single command data from an entry that is not known to contain single commands:\n  └─> {entry.tag}\n")
    entry.checkKnownKeys(CommandData,
      ["errorcodes", "successcodes", "api", "queues", "alias", "name", "cmdbufferlevel", "tasks", "renderpass", "comment", "videocoding"])
    # TODO entry.errorcodes
    # TODO entry.successcodes
    # TODO entry.api
    # TODO entry.queues
    # TODO entry.alias
    # TODO entry.name
    # TODO entry.cmdbufferlevel
    # TODO entry.tasks
    # TODO entry.renderpass
    # TODO entry.comment
    # TODO entry.videocoding
    for arg in entry:
      if arg.tag notin ["proto", "param", "implicitexternsyncparams"]: raise newException(ParsingError, &"XML data:\n{$arg}\nError when reading argument data from an arg that is not known to contain arguments:\n  └─> {arg.tag}\n")
      arg.checkKnownKeys(ParamData,
        ["optional", "externsync", "len", "noautovalidity", "stride", "api", "objecttype", "altlen", "validstructs"],
        KnownEmpty=["implicitexternsyncparams"])
      # TODO arg.optional
      # TODO arg.externsync
      # TODO arg.len
      # TODO arg.altlen
      # TODO arg.proto (tree)
      # TODO arg.noautovalidity
      # TODO arg.stride
      # TODO arg.api
      # TODO arg.objecttype
      # TODO arg.validstructs
      if arg.tag == "proto":
        for field in arg:
          # TODO proto.infix_information
          if field.kind == xnText: continue#echo "--------->\n",field.innerText(); continue
          field.checkKnownKeys(ParamData, [], KnownEmpty=["type","name"])
          if field.tag notin ["type","name"]: raise newException(ParsingError, &"XML data:\n{$field}\nError when reading prototype data from a subnode that is not known to contain proto information:\n  └─> {field.tag}\n")
          # TODO proto.type
          # TODO proto.name
      # TODO arg.param (tree)
      elif arg.tag == "param":
        for field in arg:
          # TODO param.infix_information
          if field.kind == xnText: continue#echo "--------->\n",field.innerText(); continue
          field.checkKnownKeys(ParamData, [], KnownEmpty=["type","name"])
          if field.tag notin ["type","name"]: raise newException(ParsingError, &"XML data:\n{$field}\nError when reading argument data from a subnode that is not known to contain field information:\n  └─> {field.tag}\n")
          # TODO param.type
          # TODO param.name
      # TODO arg.implicitexternsyncparams
      elif arg.tag == "implicitexternsyncparams":
        for field in arg:
          field.checkKnownKeys(ParamData, [], KnownEmpty=[])
          if field.tag notin ["param"]: raise newException(ParsingError, &"XML data:\n{$field}\nError when reading implicitexternsyncparams data from a subnode that is not known to contain them:\n  └─> {field.tag}\n")
          # TODO field.param (tree)


const genTemplate = """
{VulkanNimHeader}
import ./dynamic

## Vulkan Procedures
{procs}
"""

proc generateProcs *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_procs.nim"
  var procs :string
  writeFile(outputDir,fmt genTemplate)

