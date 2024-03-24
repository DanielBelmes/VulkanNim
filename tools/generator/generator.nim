import ./base; export base
import ./api
import ./enums
import ./extensions
import ./formats
import ./handles
import ./procs
import ./structs
import ./types

proc generate *(generator: Generator): void =
  # Generate the code files
  const C_like = true
  generator.generateAPI( C_like )
  generator.generateExtensionInspection( C_like )
  generator.generateTypes( C_like )
  generator.generateFormats( C_like )
  generator.generateConsts( C_like )
  generator.generateEnums( C_like )
  generator.generateProcs( C_like )
  generator.generateHandles( C_like )
  generator.generateStructs( C_like )