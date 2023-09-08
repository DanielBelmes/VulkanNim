# Generator dependencies
import ../dependencies ; export dependencies
import ./license       ; export license
import ./base          ; export base


#_______________________________________
# Error Management
#___________________
proc checkKnownKeys *[T](node :XmlNode; _:typedesc[T]; KnownKeys :openArray[string]) :void=
  ## Checks that all the keys in the given node are contained in the input KnownKeys.
  ## Raises an exception otherwise (for the case of newly added or changed keys in the spec)
  ## Any attribute found in the node, which is not in the list, will raise an exception
  ## and report its name and XML contents to console.
  ## The type is used as a reference for the section where the check is called from.
  ##
  ## Example Usage:
  ##   node.checkKnownKeys(EnumValueData, [ "comment", "value", "protect", "name", "alias", "deprecated" ])
  if node.attrs.isNil:
    if node.tag() == "comment": return  # We know that comment nodes can sometimes contain no attributes, so don't segfault on them.
    if node.tag() == "require": return  # We know that require nodes only contain subnodes and no attributes, so don't error because they are missing.
    else: raise newException(ParsingError, &"Tried to get {$T} information from a node that contains a tag that has no attributes:\n  └─> {node.tag()}\nIts XML data is:\n{$node}\n")
  for key in node.attrs.keys():
    if key notin KnownKeys: raise newException(ParsingError, &"Tried to get {$T} information from a node that contains an unknown key:\n  └─> {key}\nIts XML data is:\n{$node}\n")

#_______________________________________
# Generator Tools used by all modules
#___________________
func getDeprecated *(data :AliasData; name :string) :string=
  ## Returns a {.deprecated: reason.} pragma string, based on the information contained in the given AliasData
  if data.deprecated == "": return ""
  var reason :string= case data.deprecated:
  of "aliased":  &"{data.deprecated}:  {name}  has been aliased to  {data.name}"
  else: raise newException(CodegenError, &"Tried to add codegen for a deprecated alias, but it contains an unknown reason:\n └─> {data.deprecated}\n")
  result = &" {{.deprecated: \"{reason}\".}}"

