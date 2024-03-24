# Generator dependencies
import ../common


proc readPlatforms *(gen :var Generator; platforms :XmlNode) :void=
  ## Treats the given node as an platforms block, and adds its contents to the respective generator registry field.
  if platforms.tag != "platforms": raise newException(ParsingError, &"Tried to read platforms data from a node that is not known to contain platforms:\n  └─> {platforms.tag}\nIts XML data is:\n{$platforms}")
  platforms.checkKnownKeys(PlatformData, ["comment"])
  for platform in platforms:
    if platform.tag != "platform": raise newException(ParsingError, &"Tried to read platform data from a subnode that is not known to contain single platform info:\n  └─> {platform.tag}\nIts XML data is:\n{$platform}")
    platform.checkKnownKeys(PlatformData, ["name", "protect", "comment"])
    if gen.registry.platforms.containsOrIncl(platform.attr("name"), PlatformData(
      protect : platform.attr("protect"),
      comment : platform.attr("comment"),
      xmlLine : platform.lineNumber
      )): duplicateAddError("Platform",platform.attr("name"),platform.lineNumber)

