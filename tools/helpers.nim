# std dependencies
import customxmlParsing/xmltree
import std/tables
import std/re
import std/strformat
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

proc duplicateAddError*(item: string, name: string, lineNumber: int): void = raise newException(ParsingError, fmt"Tried to add a repeated {item} that already exists inside the generator. Name: {name}, Line Number: {lineNumber}")
  ## Used when a duplcate node is attemtping to be added into the registery

proc toplevelText*(node: XmlNode): string =
  ## Used to get just the top level text out of a xnElement. (see xmltree/InnerText for getting all text recursively)
  assert node.kind == xnElement
  for elem in node:
    if elem.kind == xnText:
      result &= elem.rawText()

iterator pairs*(node: XmlNode): (int,XmlNode) {.inline.} =
  ## Enables you to take out the index with a for in statement
  assert node.kind == xnElement
  var index = 0
  for child in node:
      yield (index,child)
      index+=1

proc removeExtraSpace*(str: string): string =
  ## Changes all multi spaces and tabs into one space. Trims trailing and appending whitespace as well
  return str.strip().replacef(re"[ 	]+"," ")
