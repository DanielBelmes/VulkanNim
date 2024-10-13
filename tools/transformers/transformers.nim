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
                    # TypeCategory.Bitmask
                    # TypeCategory.BaseType
                    # TypeCategory.Constant
                    # TypeCategory.Define
                    # TypeCategory.Enum
                    # TypeCategory.ExternalType
                    # TypeCategory.FuncPointer
                    # TypeCategory.Handle
                    # TypeCategory.Include
                    # TypeCategory.Struct
                    # TypeCategory.Union
                    # TypeCategory.Unknown
                for constData in requireData.enums:
                    constsToDelete.inc(constData.name)
                for commandName, commandData in requireData.commands:
                    #Removing of aliases needs more work
                    #if parser.registry.commandAliases.hasKey(commandName):
                    #    commandsToDelete.inc(parser.registry.commandAliases[commandName].name)
                    #else:
                        commandsToDelete.inc(commandName)
    proc filterCommands(command: CommandData): bool =
        if commandsToDelete.hasKey(command.proto.name):
            commandsToDelete.del(command.proto.name)
            return false
        return true
    echo fmt"Deleting {commandsToDelete.len} commands"
    parser.registry.commands = filter(parser.registry.commands, filterCommands)


proc transformDatabase*(parser: var Parser, enabledExtensions: seq[string]): void =
    echo "Transformer: TRANSFORMING DATABASE"
    #echo "Transformer: Converting Identifiers"
    transformProcsApi(parser)
    transformExtensions(parser, enabledExtensions)
    echo "Transformer: Removing Extension enum"
    echo "Transformer: Removing Extension types"
    echo "Transformer: Removing Extension commands(procs)"
    echo "Transformer: Removing Extension Alias values"
    echo "Transformer: Removing Feature types not in current api selection commands(procs)"
    echo "Transformer: Adding Feature types, enums, comands"