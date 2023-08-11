{.define: ssl.}
import strutils, httpClient, os, xmlparser, xmltree, streams
import nstd


proc main() =
  let XML = getArg(0)
  if XML == "" or not XML.endsWith(".xml"): raise newException(IOError, "The vk.xml spec file path needs to be passed to the generator as its first argument.")
  let file = newFileStream(XML, fmRead)
  let xml = file.parseXml()

when isMainModule: main()
