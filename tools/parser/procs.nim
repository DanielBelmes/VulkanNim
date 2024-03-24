# std dependencies
import std/strscans
# Generator dependencies
import ../common
import ../types


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

    # Add prototype/parameter/asyncParams to the command
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
        # -> Continue to the next proto attempt (should only have one)

      # Add parameters info to the command
      elif arg.tag == "param":
        arg.checkKnownKeys(ParamData,
          ["optional", "externsync", "noautovalidity", "stride", "objecttype", "altlen", "api", "len", "validstructs"],
          KnownEmpty=[])
        var param = ParamData(
          optional       : arg.attr("optional").split(","),
          externsync     : arg.attr("externsync").split(","),
          noautovalidity : if arg.attr("noautovalidity") != "": arg.attr("noautovalidity").parseBool() else: false,
          stride         : arg.attr("stride"),
          altlen         : arg.attr("altlen"),
          api            : arg.attr("api").split(","),
          length         : arg.attr("len"),
          validstructs   : arg.attr("validstructs"),
          xmlLine        : arg.lineNumber(),
          ) # << ParamData( ... )

        # decide if its an object
        param.isObject = arg.attr("objecttype") == "objectType"
        # get type, name and decide if it has infix information
        var hasInfix :bool
        for field in arg:
          if field.kind == xnText: hasInfix = true; continue
          if field.tag notin ["type","name"]: raise newException(ParsingError, &"XML data:\n{$field}\nError when reading argument data from a subnode that is not known to contain field information:\n  └─> {field.tag}\n")
          field.checkKnownKeys(ParamData, [], KnownEmpty=["type","name"])
          case field.tag
          of "type": param.typ.typ  = field.innerText
          of "name": param.typ.name = field.innerText
        # get prefix/postfix type info from infix text
        for field in arg:
          if not hasInfix : break
          let content = field.innerText().removeExtraSpace()
          if   content == "const"        : param.typ.prefix = content
          elif content == "struct"       : param.typ.prefix = content
          elif content == "const struct" : param.typ.prefix = content
          elif content == param.typ.typ  : continue
          elif content == param.typ.name : continue
          elif content == "*"            : param.typ.postfix = content
          elif content == "**"           : param.typ.postfix = content
          elif content == "* const*"     : param.typ.postfix = content
          elif "[" in content and "]" in content: param.typ.postfix = content
          else: raise newException(ParsingError, &"XML data:\n{$field}\nError when parsing pre/post type information from a parameter that is not mapped:\n  └─> {content}\n")

        # Add parameter to the command
        command.params.add param
        # -> Continue to the next parameter

      # Add implicit extern sync params info to the command
      elif arg.tag == "implicitexternsyncparams":
        command.asyncParams.xmlLine = arg.lineNumber()
        for field in arg:
          field.checkKnownKeys(ParamData, [], KnownEmpty=[])
          if field.tag notin ["param"]: raise newException(ParsingError, &"XML data:\n{$field}\nError when reading implicitexternsyncparams data from a subnode that is not known to contain them:\n  └─> {field.tag}\n")
          command.asyncParams.param.add field.innerText()
        # -> Continue to the next implicit extern async parameter

      # -> Continue to the command argument
    # <- Command components loop done.
    # Add the command to the registry
    gen.registry.commands.add command
