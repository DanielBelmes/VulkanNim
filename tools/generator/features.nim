# Generator dependencies
import ./common


proc readFeatures *(gen :var Generator; node :XmlNode) :void=
  ## Treats the given node as a features block, and adds its contents to the generator registry.
  if node.tag != "feature": raise newException(ParsingError, &"Tried to read features data from a node that is not known to contain features:\n  └─> {node.tag}\nIts XML data is:\n{$node}\n")
  node.checkKnownKeys(FeatureData, ["name", "api", "number", "comment"])
  var featureData = FeatureData(
    name    : node.attr("name"),
    comment : node.attr("comment"),
    number  : node.attr("number"),
    api     : node.attr("api").split(","),
    xmlLine : node.lineNumber,
    ) # << FeatureData( ... )
  # Parse the Feature entries data
  for entry in node:
    if entry.tag notin ["require","remove"]: raise newException(ParsingError, &"Tried to read feature data from a subnode that is not known to contain single features:\n  └─> {entry.tag}\nIts XML data is:\n{$node}\n\nCurrent entry:\n{$entry}\n")
    #_______________________________________
    # Parse all RequireData entries of the Feature
    if entry.tag == "require":
      entry.checkKnownKeys(RequireData, ["comment","require"])
      var data = RequireData(
        comment : entry.attr("comment"),
        depends : entry.attr("depends"),
        xmlLine : entry.lineNumber,
        ) # << RequireData( ... )
      for cct in entry: # For each command/constant/type in the require tag of the feature
        if cct.kind != xnElement: continue
        if cct.tag notin ["type","enum","command","comment"]: raise newException(ParsingError, &"Tried to read command/constant/type data from a subentry that is not known to contain them:\n  └─> {cct.tag}\nIts XML data is:\n{$entry}\n\nCurrent subentry:\n{$cct}\n")
        cct.checkKnownKeys(RequireData,
          ["name", "comment", "extends", "extnumber", "offset", "bitpos", "alias", "dir", "api", "value"])
        if   cct.tag == "type"    : data.types.add cct.attr("name")
        elif cct.tag == "command" : data.commands.add cct.attr("name")
        elif cct.tag == "comment" : # Some comments contain relevant information
          if cct.innerText.startsWith("offset "): data.missing.add cct.innerText
          else:discard # Ignore all other infix comments
        elif cct.tag == "enum"    : # Enum entries contain more data than just their name
          if data.constants.containsOrIncl( cct.attr("name"), EnumFeatureData(
            extends   : cct.attr("extends"),
            extnumber : cct.attr("extnumber"),
            offset    : cct.attr("offset"),
            bitpos    : cct.attr("bitpos"),
            alias     : cct.attr("alias"),
            dir       : cct.attr("dir"),
            api       : cct.attr("api"),
            value     : cct.attr("value"),
            xmlLine   : cct.lineNumber,
            )): duplicateAddError("RequireData EnumFeature constant",cct.attr("name"),cct.lineNumber)
      featureData.requireData.add( data )
    #_______________________________________
    # Parse all RemoveData entries of the Feature
    elif entry.tag == "remove":
      entry.checkKnownKeys(RemoveData, ["comment"])
      var data = RemoveData(
        comment : entry.attr("comment"),
        xmlLine : entry.lineNumber,
        ) # << RemoveData( ... )
      for cet in entry:
        # if cet.kind == xnComment: echo $cet # These contain information about disabled features of the spec
        if cet.kind != xnElement: continue
        if cet.tag notin ["enum","type","command"]: raise newException(ParsingError, &"Tried to read command/enum/type data from a subentry that is not known to contain them:\n  └─> {cet.tag}\nIts XML data is:\n{$entry}\n\nCurrent subentry:\n{$cet}\n")
        cet.checkKnownKeys(RemoveData, ["name"])
        if   cet.tag == "type"    : data.types.add cet.attr("name")
        elif cet.tag == "enum"    : data.enums.add cet.attr("name")
        elif cet.tag == "command" : data.commands.add cet.attr("name")
      featureData.removeData.add( data )
    else: raise newException(ParsingError, &"Tried to read data from a Feature entry that contains an ummapped key:\n  {entry.tag}\nIts XML content is:\n{$entry}")
  gen.registry.features.add(featureData)


