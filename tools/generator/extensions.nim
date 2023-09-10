# Generator dependencies
import ./common

proc readExtensions *(gen :var Generator; node :XmlNode) :void=
  if node.tag != "extensions": raise newException(ParsingError, &"XML data:\n{$node}\n\nTried to read extension data from a node that is not known to contain them:\n  └─> {node.tag}\n")
  node.checkKnownKeys(ExtensionData, ["comment"], KnownEmpty=[])
  # TODO extensions.comment
  for entry in node:
    if entry.tag notin ["extension"]: raise newException(ParsingError, &"XML data:\n{$entry}\n\nTried to read extension data from a entry that is not known to contain them:\n  └─> {entry.tag}\n")
    entry.checkKnownKeys(ExtensionData,
      ["supported", "contact", "type", "number", "ratified", "name", "author", "depends", "platform", "comment",
       "specialuse", "deprecatedby", "promotedto", "obsoletedby", "provisional", "sortorder"], KnownEmpty=[])
    var data = ExtensionData(
      supported    : entry.attr("supported").split(","),
      contact      : entry.attr("contact"),
      typ          : entry.attr("type"),
      number       : entry.attr("number"),
      ratified     : entry.attr("ratified").split(","),
      author       : entry.attr("author"),
      depends      : entry.attr("depends"),
      platform     : entry.attr("platform"),
      comment      : entry.attr("comment"),
      specialuse   : entry.attr("specialuse").split(","),
      deprecatedby : entry.attr("deprecatedby"),
      promotedto   : entry.attr("promotedto"),
      obsoletedby  : entry.attr("obsoletedby"),
      provisional  : if entry.attr("provisional") == "": false else: entry.attr("provisional").parseBool(),
      sortorder    : entry.attr("sortorder"),
      xmlLine      : entry.lineNumber,
      ) # << ExtensionData( ... )
    # Populate the requireData field
    for sub in entry:
      if sub.tag notin ["require"]: raise newException(ParsingError, &"XML data:\n{$sub}\n\nTried to read extension subdata from a subnode that is not known to contain them:\n  └─> {sub.tag}\n")
      sub.checkKnownKeys(RequireData, ["depends", "api", "comment"], KnownEmpty=[])
      var require = ExtensionRequireData(
        depends : sub.attr("depends").split(if '+' in sub.attr("depends"): "+" else: ","),
        api     : sub.attr("api").split(","),
        comment : sub.attr("comment"),
        xmlLine : sub.lineNumber,
        ) # << RequireData( ... )
      for it in sub:
        if it.kind == xnComment : continue #ignore : They are all empty
        if it.kind == xnText    : continue #ignore : They are all empty
        if it.tag notin ["enum", "type", "command", "comment"]: raise newException(ParsingError, &"XML data:\n{$it}\n\nTried to read extension sub-subdata from a second level subnode that is not known to contain them:\n  └─> {it.tag}\n")

        case it.tag
        of "enum":
          it.checkKnownKeys(RequireEnumData,
            ["value", "name", "extends", "offset", "dir", "extnumber", "comment", "bitpos", "alias", "deprecated", "api",
             "protect"], KnownEmpty=[])
          require.enums.add RequireEnumData(
            name       : it.attr("name"),
            comment    : it.attr("comment"),
            value      : it.attr("value"),
            extends    : it.attr("extends"),
            offset     : if it.attr("offset") != "": it.attr("offset").parseInt() else: 0,
            dir        : it.attr("dir"),
            extnumber  : if it.attr("extnumber") != "": it.attr("extnumber").parseInt() else: -42,
            bitpos     : it.attr("bitpos"),
            alias      : it.attr("alias"),
            deprecated : it.attr("deprecated"),
            api        : it.attr("api").split(","),
            protect    : it.attr("protect"),
            xmlLine    : it.lineNumber,
            ) # << RequireEnumData( ... )

        of "type":
          it.checkKnownKeys(RequireTypeData, ["name", "comment"], KnownEmpty=[])
          if require.types.containsOrIncl( it.attr("name"), RequireTypeData(
            comment : it.attr("comment"),
            xmlLine : it.lineNumber,
            )): duplicateAddError("RequireTypeData", it.attr("name"), it.lineNumber)

        of "command":
          it.checkKnownKeys(RequireCommandData, ["name", "comment"], KnownEmpty=[])
          if require.commands.containsOrIncl( it.attr("name"), RequireCommandData(
            comment : it.attr("comment"),
            xmlLine : it.lineNumber,
            )): duplicateAddError("RequireCommandData", it.attr("name"), it.lineNumber)

      # Add the created requireData entry
      data.requireData.add require
      # -> Continue to next require entry iteration

    # <- requireData for loop done
    # Add the extension to the registry
    if gen.registry.extensions.containsOrIncl( entry.attr("name"), data ):
       duplicateAddError("ExtensionData", entry.attr("name"), entry.lineNumber)


const genTemplate = """
{VulkanNimHeader}

## Vulkan Extension Inspection
{extensions}
"""

proc generateExtensionInspection *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_extension_inspection.nim"
  var extensions :string
  writeFile(outputDir,fmt genTemplate)


