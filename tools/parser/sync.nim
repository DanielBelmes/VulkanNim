# Generator dependencies
import ../base
import ../common

proc readSync *(gen :var Generator; node :XmlNode) :void=
  if node.tag != "sync": raise newException(ParsingError, &"XML data:\n{$node}\n\nTried to read sync data from a node that is not known to contain sync information:\n  └─> {node.tag}\n")
  node.checkKnownKeys(SyncData, ["comment"], KnownEmpty=[])
  var data = SyncData(comment: node.attr("comment"))
  for entry in node:
    if entry.tag notin ["syncstage", "syncaccess", "syncpipeline"]: raise newException(ParsingError, &"XML data:\n{$entry}\n\nTried to read single sync data from an entry that is not known to contain sync information:\n  └─> {entry.tag}\n")

    case entry.tag
    of "syncstage":
      entry.checkKnownKeys(SyncData, ["alias", "name"], KnownEmpty=[])
      var stage = SyncStageData(alias: entry.attr("alias"), xmlLine: entry.lineNumber)
      for sync in entry:
        if sync.tag notin ["syncsupport", "syncequivalent"]: raise newException(ParsingError, &"XML data:\n{$sync}\n\nTried to get syncstage data from a node that contains an unknown tag:\n └─> {$sync.tag}")
        case sync.tag
        of "syncsupport":
          sync.checkKnownKeys(SyncSupportData, ["queues"], KnownEmpty=[])
          if stage.support.containsOrIncl( sync.attr("name"), SyncSupportData(
            queues  : sync.attr("queues"),
            xmlLine : sync.lineNumber,
            )): duplicateAddError("SyncStageData", sync.attr("name"), sync.lineNumber)
        of "syncequivalent":
          sync.checkKnownKeys(SyncEquivalentData, ["stage"], KnownEmpty=[])
          if stage.equivalent.containsOrIncl( sync.attr("name"), SyncEquivalentData(
            stage   : sync.attr("stage"),
            xmlLine : sync.lineNumber,
            )): duplicateAddError("SyncStageData", sync.attr("name"), sync.lineNumber)
      # Add the stage to the SyncData object
      if data.stages.containsOrIncl( entry.attr("name"), stage): duplicateAddError("SyncStageData",entry.attr("name"),entry.lineNumber)

    of "syncaccess":
      entry.checkKnownKeys(SyncData, ["alias", "name"], KnownEmpty=[])
      var access = SyncAccessData(alias: entry.attr("alias"), xmlLine: entry.lineNumber)
      for acs in entry:
        if acs.tag notin ["syncsupport", "syncequivalent", "comment"]: raise newException(ParsingError, &"XML data:\n{$acs}\n\nTried to get syncaccess data from a node that contains an unknown tag:\n └─> {$acs.tag}")
        case acs.tag
        of "syncsupport":
          acs.checkKnownKeys(SyncSupportData, ["stage"], KnownEmpty=[])
          if access.support.containsOrIncl( acs.attr("name"), SyncSupportData(
            stage   : acs.attr("stage"),
            xmlLine : acs.lineNumber,
            )): duplicateAddError("SyncAccessData", acs.attr("name"), acs.lineNumber)
        of "syncequivalent":
          acs.checkKnownKeys(SyncEquivalentData, ["access"], KnownEmpty=[])
          if access.equivalent.containsOrIncl( acs.attr("name"), SyncEquivalentData(
            access  : acs.attr("access"),
            xmlLine : acs.lineNumber,
            )): duplicateAddError("SyncAccessData", acs.attr("name"), acs.lineNumber)
        of "comment": access.comment = acs.innerText()
      # Add the access to the SyncData object
      if data.access.containsOrIncl( entry.attr("name"), access): duplicateAddError("SyncStageData",entry.attr("name"),entry.lineNumber)

    of "syncpipeline":
      entry.checkKnownKeys(SyncPipelineData, ["alias", "name", "depends"], KnownEmpty=[])
      var pipeline = SyncPipelineData(
        alias   : entry.attr("alias"),
        depends : entry.attr("depends"),
        xmlLine : entry.lineNumber,
        ) # << SyncPipelineData( ... )
      for pipel in entry:
        if pipel.tag notin ["syncpipelinestage"]: raise newException(ParsingError, &"XML data:\n{$pipel}\n\nTried to get syncpipeline data from a node that contains an unknown tag:\n └─> {$pipel.tag}")
        case pipel.tag
        of "syncpipelinestage":
          pipel.checkKnownKeys(SyncPipelineStageData, ["order", "before"], KnownEmpty=["syncpipelinestage"])
          pipeline.stage.add SyncPipelineStageData( # these nodes have no name. cannot be table
            order   : pipel.attr("order"),
            before  : pipel.attr("before"),
            xmlLine : pipel.lineNumber,
            ) # << SyncPipelineData( ... )
        else: pipel.checkKnownKeys(SyncPipelineStageData, [], KnownEmpty=["syncpipelinestage"])
      # Add the sync pipeline data to the SyncData object
      if data.pipelines.containsOrIncl( entry.attr("name"), pipeline): duplicateAddError("SyncStageData", entry.attr("name"), entry.lineNumber)
  # Apply the IR to the generator
  gen.registry.sync = data

