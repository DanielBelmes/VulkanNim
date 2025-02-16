import ../parser/base; export base
import std/sugar
import std/sequtils

proc transformProcsApi(parser: var Parser): void =
    parser.registry.commands = collect(newSeq):
        for command in parser.registry.commands:
            if command.api == "" or command.api == parser.api:
                command

# Go through each extension. If it is enabled add values in
# If extension is disabled then remove needed values from database
proc transformExtensions(parser: var Parser, enabledExtensions: seq[string]): void =
    var typesToDelete, constsToDelete, commandsToDelete: CountTable[string]
    for extensionName, extension in parser.registry.extensions:
        if enabledExtensions.contains(extensionName):
            #load extension Data
            continue
        else:
            #Delete extension Data
            for requireData in extension.requireData:
                for typName, typData in requireData.types:
                    typesToDelete.inc(typName)
                for constData in requireData.enums:
                    constsToDelete.inc(constData.name)
                for commandName, commandData in requireData.commands:
                    commandsToDelete.inc(commandName)
    
    # Ensure that shared types, commands, and consts aren't removed in next step
    for extensionName in enabledExtensions:
        for requireData in parser.registry.extensions[extensionName].requireData:
                for typName, typData in requireData.types:
                    typesToDelete.del(typName)
                for constData in requireData.enums:
                    constsToDelete.del(constData.name)
                for commandName, commandData in requireData.commands:
                    commandsToDelete.del(commandName)

    proc filterCommands(command: CommandData): bool =
        return not commandsToDelete.hasKey(command.proto.name)
    echo fmt"Deleting {commandsToDelete.len} extension commands from registry"
    parser.registry.commands = filter(parser.registry.commands, filterCommands)
    echo fmt"Deleting {typesToDelete.len} extension types from registry"
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
    echo "Leftover Types that might be shared or never got added to registry during parsing:"
    echo typesToDelete

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
                        parser.registry.enums[constData.extends].values[constName] = EnumValueData(
                            comment  : "",
                            value    : "0", # todo - NEED TO CALCULATE ACTUAL VALUE WITH THAT DUMB FORMULA
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
    echo "Leftover Types that might be shared or never got added to registry during parsing:"
    echo typesToDelete


proc transformDatabase*(parser: var Parser, enabledExtensions: seq[string]): void =
    echo "Transformer: TRANSFORMING DATABASE"
    transformProcsApi(parser)
    transformExtensions(parser, enabledExtensions)
    transformFeatures(parser)
