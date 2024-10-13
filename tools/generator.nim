# std dependencies
import std/streams
# External dependencies
import nstd
# parser dependencies
import ./parser/parser
import ./generator/generator
import ./transformers/transformers

#_______________________________________
# Generator Entry Point
#___________________
# CLI helper docs
const DefaultAPI = "vulkan"
const ValidAPIs  = ["vulkan", "vulkansc"]
const Help = &"""
Usage:
- First argument:  Must always be a valid vk.xml spec file.
  Note: Validity of the file is only checked by extension, and will crash the XML parser if its has invalid xml contents.
- Second argument (optional):
  A targetAPI keyword can be provided. Valid keywords:  {ValidAPIs}
  Will default to "{DefaultAPI}" when omitted.
"""
static:assert DefaultAPI in ValidAPIs
#___________________
# Entry Point
proc main=
  # Interpret the arguments given to the generator
  let args = nstd.getArgs()
  var enabledExtensions: seq[string] = @[#[ "VK_KHR_portability_subset","VK_KHR_swapchain" ]#]
  var XML, targetAPI: string
  if args.len in 1..2:
    if not args[0].endsWith(".xml"): raise newException(ArgsError, &"The first argument input must be a valid .xml file. See {Help}")
    XML = args[0]
  if args.len == 2:
    if args[1] notin ValidAPIs: raise newException(ArgsError, "The desired target API needs to be either omitted, or passed to the generator as its second argument. The known valid options are:\n{ValidAPIs}")
    targetAPI = args[1]
  elif args.len == 1:
    targetAPI = DefaultAPI # Assume normal vulkan (not sc) when omitted.
  elif args.len == 0 : raise newException(ArgsError, &"No arguments provided. See {Help}")
  else               : raise newException(ArgsError, &"Too many arguments provided. See {Help}")

  # Read the file into an XML tree
  var file = newFileStream(XML,fmRead)
  var parser = Parser(doc : file.parseXml(),
    api : targetAPI )

  parser.readRegistry() #Parse XML into IR

  transformDatabase(parser, enabledExtensions) #Modify registry databse based on enabled api, features, and extensions

  var generator = Generator(
    api : targetAPI,
    registry: parser.registry )

  generator.generate() #Generate Library


when isMainModule: main()
