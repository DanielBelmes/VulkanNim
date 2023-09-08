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
    # TODO extension.supported
    # TODO extension.contact
    # TODO extension.type
    # TODO extension.number
    # TODO extension.ratified
    # TODO extension.name
    # TODO extension.author
    # TODO extension.depends
    # TODO extension.platform
    # TODO extension.comment
    # TODO extension.specialuse
    # TODO extension.deprecatedby
    # TODO extension.promotedto
    # TODO extension.obsoletedby
    # TODO extension.provisional
    # TODO extension.sortorder
    for sub in entry:
      # TODO extension.require (list)
      if sub.tag notin ["require"]: raise newException(ParsingError, &"XML data:\n{$sub}\n\nTried to read extension subdata from a subnode that is not known to contain them:\n  └─> {sub.tag}\n")
      sub.checkKnownKeys(RequireData, ["depends", "api", "comment"], KnownEmpty=[])
      # TODO req.depends
      # TODO req.api
      # TODO req.comment
      for it in sub:
        if it.kind == xnComment : continue # TODO req.comment (innerText)
        if it.kind == xnText    : continue # TODO req.comment (innerText)
        if it.tag notin ["enum", "type", "command", "comment"]: raise newException(ParsingError, &"XML data:\n{$it}\n\nTried to read extension sub-subdata from a second level subnode that is not known to contain them:\n  └─> {it.tag}\n")
        # TODO req.comment (innerText)
        # TODO req.enum (list)
        case it.tag
        of "enum":
          it.checkKnownKeys(RequireEnumData,
            ["value", "name", "extends", "offset", "dir", "extnumber", "comment", "bitpos", "alias", "deprecated", "api",
             "protect"], KnownEmpty=[])
          # TODO enum.value
          # TODO enum.name
          # TODO enum.extends
          # TODO enum.offset
          # TODO enum.dir
          # TODO enum.extnumber
          # TODO enum.comment
          # TODO enum.bitpos
          # TODO enum.alias
          # TODO enum.deprecated
          # TODO enum.api
          # TODO enum.protect
        # TODO req.type (list)
        of "type":
          it.checkKnownKeys(RequireTypeData, ["name", "comment"], KnownEmpty=[])
          # TODO type.name
          # TODO type.comment
        # TODO req.command (list)
        of "command":
          it.checkKnownKeys(RequireCommandData, ["name", "comment"], KnownEmpty=[])
          # TODO cmd.name
          # TODO cmd.comment


const genTemplate = """
{VulkanNimHeader}

## Vulkan Extension Inspection
{extensions}
"""

proc generateExtensionInspection *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_extension_inspection.nim"
  var extensions :string
  writeFile(outputDir,fmt genTemplate)


