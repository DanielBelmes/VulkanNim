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
  generator.generateAPI()
  generator.generateExtensionInspection()
  generator.generateTypes()
  generator.generateFormats()
  generator.generateConsts()
  generator.generateEnums()
  generator.generateProcs()
  generator.generateHandles()
  generator.generateStructs()