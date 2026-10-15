# std dependencies
import std/os
import std/strformat
import std/strutils
# generator dependencies
from ./helpers import getArgs, ArgsError, CodegenError
from ./generator/unchanged import nil

#_______________________________________
# Generator Entry Point
#___________________
# CLI helper docs
const DefaultAPI = "vulkan"
const ValidAPIs  = ["vulkan", "vulkansc"]
const Binary     = "VulkanObjectAST"
const VulkanAST  = "bin"/"vulkan.atf"
const Unchanged  = "src"/"VulkanNim"/"unchanged.nim"
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
proc converter_binary () :string=
  result = findExe(Binary)
  if result.len > 0: return
  let local = "bin"/Binary.addFileExt(ExeExt)
  if fileExists(local): return local
  return ""
#___________________
# Entry Point
proc main=
  # Interpret the arguments given to the generator
  let args = helpers.getArgs()
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
  #___________________
  # Run the VulkanObjectAST converter binary
  let bin = converter_binary()
  if bin.len == 0: raise newException(CodegenError, &"{Binary} was not found. Install it into your PATH, or place it at {\"bin\"/Binary}")
  let code = execShellCmd(&"{bin} --spec={XML} --output={VulkanAST}")
  if code != 0: raise newException(CodegenError, &"{Binary} failed to convert {XML}. Exit code: {code}")
  #___________________
  # Parse + process + codegen vulkan.atf with nonim
  let api_unchanged = unchanged.generate(VulkanAST.readFile())
  Unchanged.parentDir().createDir()
  Unchanged.writeFile(api_unchanged)
#___________________
when isMainModule: main()

