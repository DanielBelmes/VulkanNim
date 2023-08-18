# std dependencies
import std/xmlparser
import std/xmltree
import std/tables
import std/re
import std/strutils
# Generator dependencies
import ./generator/common

iterator findElems *(node :XmlNode; name :string) :XmlNode=
  ## Yields all xnElement nodes contained in the given XmlNode that match the given name.
  for node in node.findAll(name):
    case node.kind:
    of xnText, xnVerbatimText, xnCData, xnEntity, xnComment: continue
    of xnElement: yield node

type SomeTable[A,B] = Table[A,B] | OrderedTable[A,B] | CountTable[A]
proc containsOrIncl *[A, B](table :var SomeTable[A,B]; key :A; value :B) :bool=
  if key in table: return true
  table[key] = value


template unreachable *(msg :string= "")=  raise newException(Unreachable, msg)
  ## Used to mark a block of code as unreachable, and raise an exception when actually entering the block.
  ## Useful to debug for difficult to track edge cases and work in progress sections of parsing.

proc toplevelText*(node: XmlNode): string =
  for elem in node:
    if elem.kind == xnText:
      result &= elem.rawText()

iterator pairs*(node: XmlNode): (int,XmlNode) {.inline.} =
    assert node.kind == xnElement
    var index = 0
    for node in node:
        yield (index,node)
        index+=1

proc removeExtraSpace*(str: string): string =
    return str.strip().replacef(re"[ 	]+"," ") #remove trailing and appending whitespace then reduce excess whitespace
