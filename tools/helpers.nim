# std dependencies
import std/tables
import std/re
import std/strformat
import std/strutils
# External dependencies
import nstd/format as nstdFormat ; export nstdFormat
# Generator dependencies
import ./customxml

#___________________
type ArgsError     * = object of CatchableError  ## For errors in input arguments into the generator
type ParsingError  * = object of CatchableError  ## For errors when parsing the spec XML tree into its IR data
type CodegenError  * = object of CatchableError  ## For errors during Nim code generation from the IR data
type Unreachable   * = object of Defect          ## For use inside the `unreachable "msg"` template
#___________________

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
  ## Used when a duplcate node is attemtping to be added into the registry

proc toplevelText*(node: XmlNode): string =
  ## Used to get just the top level text out of a xnElement. (see xmltree/InnerText for getting all text recursively)
  assert node.kind == xnElement
  for elem in node:
    if elem.kind == xnText:
      result &= elem.text()

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

proc removePrefix*(s: string, prefix: string): string =
  ## Removes prefix and returns modified string
  if s.startsWith(prefix) and prefix.len > 0:
    return s[prefix.len..^1]
  else:
    return s

proc removeSuffix*(s: string, prefix: string): string =
  # Removes suffix and returns modified string
  if s.endsWith(prefix) and prefix.len > 0:
    return s[0..((len(s) - 1) - prefix.len)] # ^1 macro wasn't working here
  else:
    return s

proc removeSlashNewLine*(s:string): string =
  return s.replace(re"\\\n","")

func symbolToNim *(sym :string) :string=
  ## Converts the given Vulkan Symbol format to our Nim styling convention
  ## TODO: Keep Vendor symbols and EXT in ALLCAPS
  #   Algorithm:    (requires having (or passing) a list of vendors to this function)
  #   1. Check for whether sym.endsWith(SomeVendor)
  #   2. Store SomeVendor string
  #   3. Remove it from the end of the string
  #   4. Reformat the string
  #   5. Add it back
  ##
  ## `VK_`, `Vk` and `vk` are removed.
  ## `VK_SCREAM_CASE` and `VkPascalCase` are converted to PascalCase.
  ## `vkCamelCase` is converted to `camelCase`
  if    sym.startsWith("VK_") : result = sym[3..^1].change( SCREAM_CASE, PascalCase )
  elif  sym.startsWith("Vk")  : result = sym[2..^1].change(  PascalCase, PascalCase )
  elif  sym.startsWith("vk")  : result = sym[2..^1].change(  PascalCase, camelCase  )
  else: raise newException(CodegenError, &"Tried to convert a symbol name with a condition that hasn't been mapped yet:\n  {sym}")

proc find*[T](s: seq[T], pred: proc(x: T): bool): int =
  ## Finds the first item from sequence that satisfies procedure
  ## returns index of item. If not item is found return -1
  for index, item in s:
    if (pred(item)):
      return index
  return -1