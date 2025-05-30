import ../parser/base; export base
import std/sugar
import std/sequtils
import std/bitops

proc getEnumValue(enumData: EnumFeatureData | RequireEnumData): int64 =
  if enumData.value != "":
    var enumValueStr = c2NimType(enumData.value,0)

    if enumValueStr.contains('x'):
      result = fromHex[int](enumValueStr)
    else:
      result = enumValueStr.parseInt()
  if enumData.bitpos != "":
    result.setBit(enumData.bitpos.parseInt())
  if enumData.offset >= 0:
    const base_value = 1000000000
    const range_size = 1000
    let offset = enumData.offset
    let extnumber = enumData.extnumber
    let enumNegative = enumData.dir != "" #Direction
    var num = base_value + (extnumber - 1) * range_size + offset
    if enumNegative:
      num *= -1
    result = num

proc transformProcsApi(parser: var Parser): void =
    parser.registry.commands = collect(newSeq):
        for command in parser.registry.commands:
            if command.api == "" or command.api == parser.api:
                command

# Go through each extension. If it is enabled add values in
# If extension is disabled then remove needed values from database
proc transformExtensions(parser: var Parser): void =
    # Ensure that shared types, commands, and consts aren't removed in next step
    for extensionName, extensionData in parser.registry.extensions:
        for requireData in parser.registry.extensions[extensionName].requireData:
                for constData in requireData.enums:
                    if constData.alias == "" and constData.extends in parser.registry.enums:
                        parser.registry.enums[constData.extends].values[constData.name] = EnumValueData(
                                    comment  : "",
                                    value    : intToStr(getEnumValue(constData)), # todo - NEED TO CALCULATE ACTUAL VALUE WITH THAT DUMB FORMULA
                                    protect  : "",
                                    xmlLine  : constData.xmlLine,
                                    )

proc transformFeatures(parser: var Parser): void =
    var typesToDelete, constsToDelete, commandsToDelete: CountTable[string]
    for feature in parser.registry.features:
        if parser.api notin feature.api:
            for requireData in feature.requireData:
                for typName in requireData.types:
                    typesToDelete.inc(typName)
                for constName, constData in requireData.constants:
                    constsToDelete.inc(constName)
                for commandName in requireData.commands:
                    commandsToDelete.inc(commandName)
        else:
            for requireData in feature.requireData:
                for constName, constData in requireData.constants:
                    if constData.extends in parser.registry.enums:
                        if(constData.alias == ""):
                            parser.registry.enums[constData.extends].values[constName] = EnumValueData(
                                comment  : "",
                                value    : intToStr(getEnumValue(constData)), # todo - NEED TO CALCULATE ACTUAL VALUE WITH THAT DUMB FORMULA
                                protect  : "",
                                xmlLine  : constData.xmlLine,
                                )
    proc filterCommands(command: CommandData): bool =
        return not commandsToDelete.hasKey(command.proto.name)
    echo fmt"Deleting {commandsToDelete.len} feature commands from registry"
    parser.registry.commands = filter(parser.registry.commands, filterCommands)
    echo fmt"Deleting {typesToDelete.len} feature types from registry"
    for `type`, count in typesToDelete.mpairs:
        # TODO - this code is kinda ugly and wouldn't hurt to cleanup later
        # TODO - Also it does not know if another EXT is using the type
        if(parser.registry.baseTypes.hasKey(`type`)):
            count -= 1
            continue #base types get to stay
        discard parser.registry.types.pop(`type`) #Don't increment counter since all types are duplicated here
        if parser.registry.bitmasks.pop(`type`):
            count -= 1
        if parser.registry.bitmaskAliases.pop(`type`):
            count -= 1
        if parser.registry.structs.pop(`type`):
            count -= 1
        if parser.registry.structAliases.pop(`type`):
            count -= 1
        if parser.registry.funcPointers.pop(`type`):
            count -= 1
        if parser.registry.handles.pop(`type`):
            count -= 1
        if parser.registry.handleAliases.pop(`type`):
            count -= 1
        if parser.registry.enums.pop(`type`):
            count -= 1
        if parser.registry.enumAliases.pop(`type`):
            count -= 1
    # echo "Leftover Types that might be shared or never got added to registry during parsing:"
    # echo typesToDelete


proc transformDatabase*(parser: var Parser): void =
    echo "Transformer: TRANSFORMING DATABASE"
    transformProcsApi(parser)
    transformFeatures(parser)
    transformExtensions(parser)
