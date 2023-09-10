# Generator dependencies
import ./common


proc readProcs *(gen :var Generator; node :XmlNode) :void=
  ## Treats the given node as a procs block, and adds its contents to the generator registry.
  ## Vulkan procs are called commands in the spec.
  if node.tag != "commands": raise newException(ParsingError, &"XML data:\n{$node}\nError when reading commands data from a node that is not known to contain commands:\n  └─> {node.tag}\n")
  node.checkKnownKeys(CommandData, ["comment"])
  # TODO: cmd.comment
  for entry in node:
    if entry.tag != "command": raise newException(ParsingError, &"XML data:\n{$entry}\nError when reading single command data from an entry that is not known to contain single commands:\n  └─> {entry.tag}\n")
    entry.checkKnownKeys(CommandData,
      ["errorcodes", "successcodes", "api", "queues", "alias", "name", "cmdbufferlevel", "tasks", "renderpass", "comment", "videocoding"])
    var command = CommandData(
       name           : entry.attr("name"),
       errorcodes     : entry.attr("errorcodes").split(","),
       successcodes   : entry.attr("successcodes").split(","),
       api            : entry.attr("api").split(","),
       queues         : entry.attr("queues").split(","),
       alias          : entry.attr("alias"),
       cmdbufferlevel : entry.attr("cmdbufferlevel").split(","),
       tasks          : entry.attr("tasks").split(","),
       renderpass     : entry.attr("renderpass"),
       comment        : entry.attr("comment"),
       videocoding    : entry.attr("videocoding"),
       xmlLine        : entry.lineNumber(),
       ) # << CommandData( ... )

    for arg in entry:
      if arg.tag notin ["proto", "param", "implicitexternsyncparams"]: raise newException(ParsingError, &"XML data:\n{$arg}\nError when reading argument data from an arg that is not known to contain arguments:\n  └─> {arg.tag}\n")
      arg.checkKnownKeys(ParamData,
        ["optional", "externsync", "noautovalidity", "stride", "objecttype", "altlen", "api", "len", "validstructs"],
        KnownEmpty=["implicitexternsyncparams"])

      # Add prototype info to the command
      if arg.tag == "proto":
        command.proto.xmlLine = arg.lineNumber()
        for field in arg:
          field.checkKnownKeys(ParamData, [], KnownEmpty=["type","name"])
          if field.tag notin ["type","name"]: raise newException(ParsingError, &"XML data:\n{$field}\nError when reading prototype data from a subnode that is not known to contain proto information:\n  └─> {field.tag}\n")
          case field.tag
          of "type":
            if command.proto.typ != "": raise newException(ParsingError, &"XML data:\nTried to add ProtoData Type information to a command that already has it.\n  └─> {command}")
            command.proto.typ = field.innerText()
          of "name":
            if command.proto.name != "": raise newException(ParsingError, &"XML data:\nTried to add ProtoData Name information to a command that already has it.\n  └─> {command}")
            command.proto.name = field.innerText()

      # TODO arg.param (tree)
      # Add parameters info to the command
      elif arg.tag == "param":
        arg.checkKnownKeys(ParamData,
          ["optional", "externsync", "noautovalidity", "stride", "objecttype", "altlen", "api", "len", "validstructs"],
          KnownEmpty=[])
        command.params.add ParamData(
          optional       : arg.attr("optional").split(","),
          externsync     : arg.attr("externsync").split(","),
          noautovalidity : if arg.attr("noautovalidity") != "": arg.attr("noautovalidity").parseBool() else: false,
          stride         : arg.attr("stride"),
          objecttype     : arg.attr("objecttype"),
          altlen         : arg.attr("altlen"),
          api            : arg.attr("api").split(","),
          length         : arg.attr("len"),
          validstructs   : arg.attr("validstructs"),
          xmlLine        : arg.lineNumber(),
          ) # << ParamData( ... )


        for field in arg:

          # TODO param.infix_information
          if field.kind == xnText: continue#echo "--------->\n",field.innerText(); continue

          if field.tag() == "name":
            let tmp = field.innerText()
            if tmp != "": echo tmp, "\n",arg,"\n\n"

          field.checkKnownKeys(ParamData, [], KnownEmpty=["type","name"])
          if field.tag notin ["type","name"]: raise newException(ParsingError, &"XML data:\n{$field}\nError when reading argument data from a subnode that is not known to contain field information:\n  └─> {field.tag}\n")
          # TODO param.type
          # TODO param.name

      # Add implicit extern sync params info to the command
      elif arg.tag == "implicitexternsyncparams":
        command.asyncParams.xmlLine = arg.lineNumber()
        for field in arg:
          field.checkKnownKeys(ParamData, [], KnownEmpty=[])
          if field.tag notin ["param"]: raise newException(ParsingError, &"XML data:\n{$field}\nError when reading implicitexternsyncparams data from a subnode that is not known to contain them:\n  └─> {field.tag}\n")
          command.asyncParams.param.add field.innerText()

    # Add the command to the registry
    gen.registry.commands.add command


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

