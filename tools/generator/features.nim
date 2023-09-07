# std dependencies
import std/strformat
import std/strutils
# Generator dependencies
import ../customxmlParsing/xmlparser, ../customxmlParsing/xmltree
import ../helpers
import ./common


proc readFeatures *(gen :var Generator; node :XmlNode) :void=
  if node.tag != "feature": raise newException(ParsingError, &"Tried to read features data from a node that is not known to contain features:\n  └─> {node.tag}\nIts XML data is:\n{$node}\n")
  node.checkKnownKeys(FeatureData, ["name", "api", "number", "comment"])
  var featureData = FeatureData(
    name    : node.attr("name"),
    comment : node.attr("comment"),
    number  : node.attr("number"),
    api     : node.attr("api").split(","),
    xmlLine : node.lineNumber,
    ) # << FeatureData( ... )
  for entry in node:
    if entry.tag notin ["require","remove"]: raise newException(ParsingError, &"Tried to read feature data from a subnode that is not known to contain single features:\n  └─> {entry.tag}\nIts XML data is:\n{$entry}\n")
    if entry.tag == "require":
      entry.checkKnownKeys(RequireData, ["comment","require"])
      var data = RequireData(
        comment : entry.attr("comment"),
        depends : entry.attr("depends"),
        xmlLine : entry.lineNumber,
        ) # << RequireData( ... )
      for cct in entry: # For each command/constant/type in the require tag of the feature

        # TODO: Continue parsing this correctly with error checking
        if off and cct.tag notin ["type","enum","command"]:
          echo entry
          raise newException(ParsingError, &"Tried to read command/constant/type data from a subentry that is not known to contain them:\n  └─> {cct.tag}\nIts XML data is:\n{$cct}\n")

        # cct.checkKnownKeys(RequireData, ["name", "comment"])
        if cct.kind != xnElement: continue
        if   cct.tag == "type"    : data.types.add cct.attr("name")
        elif cct.tag == "enum"    : data.constants.add cct.attr("name")
        elif cct.tag == "command" : data.commands.add cct.attr("name")
      featureData.requireData.add( data )
    elif entry.tag == "remove":
      var removeData: RemoveData
      removeData.xmlLine = entry.lineNumber
      for commandEnumType in entry:
        if commandEnumType.kind != xnElement: continue
        if commandEnumType.tag == "type":
          removeData.types.add(commandEnumType.attr("name"))
        if commandEnumType.tag == "enum":
          removeData.enums.add(commandEnumType.attr("name"))
        if commandEnumType.tag == "command":
          removeData.commands.add(commandEnumType.attr("name"))
      featureData.removeData.add(removeData)
  gen.registry.features.add(featureData)


