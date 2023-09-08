# Generator dependencies
import ./base
import ./common

proc readSync *(gen :var Generator; node :XmlNode) :void=
  if node.tag != "sync": raise newException(ParsingError, &"XML data:\n{$node}\n\nTried to read sync data from a node that is not known to contain sync information:\n  └─> {node.tag}\n")
  node.checkKnownKeys(SyncData, ["comment"], KnownEmpty=[])
  # TODO: sync.comment
  for entry in node:
    if entry.tag notin ["syncstage", "syncaccess", "syncpipeline"]: raise newException(ParsingError, &"XML data:\n{$entry}\n\nTried to read single sync data from an entry that is not known to contain sync information:\n  └─> {entry.tag}\n")
    # TODO entry.syncstage    (tree)
    case entry.tag
    of "syncstage":
      entry.checkKnownKeys(SyncData, ["alias", "name"], KnownEmpty=[])
      for stage in entry:
        if stage.tag notin ["syncsupport", "syncequivalent"]: raise newException(ParsingError, &"XML data:\n{$stage}\n\nTried to get syncstage data from a node that contains an unknown tag:\n └─> {$stage.tag}")
        # TODO stage.alias
        # TODO stage.name
        # TODO stage.syncsupport    (tree)
        # TODO stage.syncequivalent (tree)
    # TODO entry.syncaccess   (tree)
    of "syncaccess":
      entry.checkKnownKeys(SyncData, ["alias", "name"], KnownEmpty=[])
      for acs in entry:
        if acs.tag notin ["syncsupport", "syncequivalent", "comment"]: raise newException(ParsingError, &"XML data:\n{$acs}\n\nTried to get syncaccess data from a node that contains an unknown tag:\n └─> {$acs.tag}")
        # TODO acs.alias
        # TODO acs.name
        # TODO acs.syncsupport    (tree)
        # TODO acs.syncequivalent (tree)
        # TODO acs.comment
    # TODO entry.syncpipeline (tree)
    of "syncpipeline":
      entry.checkKnownKeys(SyncData, ["alias", "name", "depends"], KnownEmpty=[])
      for pipel in entry:
        if pipel.tag notin ["syncpipelinestage"]: raise newException(ParsingError, &"XML data:\n{$pipel}\n\nTried to get syncpipeline data from a node that contains an unknown tag:\n └─> {$pipel.tag}")
        # TODO pipel.alias
        # TODO pipel.name
        # TODO pipel.depends
        # TODO pipel.syncpipelinestage (tree)
    # echo entry, "\n\n"

