# std dependencies
import ../customxmlParsing/xmltree, std/tables, std/sets


# Error Management
type ArgsError     * = object of CatchableError  ## For errors in input arguments into the generator
type ParsingError  * = object of CatchableError  ## For errors when parsing the spec XML tree into its IR data
type CodegenError  * = object of CatchableError  ## For errors during Nim code generation from the IR data
type Unreachable   * = object of Defect          ## For use inside the `unreachable "msg"` template
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
    else: raise newException(ParsingError, &"Tried to get {$T} information from a node that contains a tag that has no attributes:\n  └─> {node.tag()}\nIts XML data is:\n{$node}\n")
  for key in node.attrs.keys():
    if key notin KnownKeys: raise newException(ParsingError, &"Tried to get {$T} information from a node that contains an unknown key:\n  └─> {key}\nIts XML data is:\n{$node}\n")


type TypeCategory* {.pure.}= enum
  Bitmask,
  BaseType,
  Constant,
  Define,
  Enum,
  ExternalType,
  FuncPointer,
  Handle,
  Include,
  Struct,
  Union,
  Unknown

type TypeData* = object
  category: TypeCategory = TypeCategory.Unknown
  requiredBy: OrderedSet[string]
  xmlLine: int

type TypeInfo* = object
  prefix*: string
  `type`*: string
  postfix*: string

type BaseTypeData* = object
  typeInfo  *:TypeInfo
  xmlLine   *:int

type AliasData * = object
  name       *:string
  deprecated *:string  # Information for adding the {.deprecated: reason.} pragma. Contained in the XML, useful for nim too
  api        *:string  # Known values: "vulkan" and "vulkansc"
  xmlLine    *:int

type BitmaskValueData * = object
  comment  *:string
  bitpos   *:string
  protect  *:string  # Only bitmask values added by the Extensions section have this field active. Not in the main list.
  xmlLine  *:int

type BitmaskData * = object
  bitwidth  *:string
  require   *:string  # Not used in the main enum-bitmask list. Added only in the types section.
  typ       *:string
  xmlLine   *:int

type EnumValueData * = object
  ## Represents the IR data for a single field in a Vulkan Enum set
  comment  *:string
  value    *:string
  protect  *:string  # Only enum values added by the Extensions section have this field active. Not in the main list.
  xmlLine  *:int

type EnumData * = object
  ## Represents the IR data for a Vulkan Enum set, and all of its contained fields.
  comment  *:string
  values   *:OrderedTable[string, EnumValueData]
  unused   *:string
  xmlLine  *:int

##[ OLD ]#______________________________________________________________________
# TODO: Remove
type EnumData* = object
  # bitwidth           *:string
  # isBitmask          *:bool
  unsupportedValues  *:seq[EnumValueData]
  # values             *:OrderedTable[string, EnumValueData]
  # xmlLine            *:int
]###______________________________________________________________________

type NameData* = object
  name*: string
  arraySizes*: seq[string]

type ParamData* = object
  `type`*: TypeInfo
  name*: string
  arraySizes*: seq[string]
  lenExpression*: string
  lenParams*: seq[(string, csize_t)]
  optional*: bool = false
  strideParam*: (string, csize_t)
  xmlLine*: int

type CommandData* = object
  errorCodes*: seq[string]
  handle*: string
  params*: seq[ParamData]
  requiredBy*: OrderedSet[string]
  returnType*: string
  successCodes*: seq[string]
  xmlLine*: int

type ConstantData* = object
  typ      *:string
  value    *:string
  xmlLine  *:int

type DefineData* = object
  deprecated*: bool = false
  require*: string
  xmlLine*: int
  deprecationReason*: string
  possibleCallee*: string
  params*: seq[string]
  possibleDefinition*: string

type DefinesPartition* = object
  callees*: OrderedTable[string, DefineData]
  callers*: OrderedTable[string, DefineData]
  values*: OrderedTable[string, DefineData]

type RemoveData* = object
  commands*: seq[string]
  enums*: seq[string]
  types*: seq[string]
  xmlLine*: int

type RequireData* = object
  depends*: string
  commands*: seq[string]
  constants*: seq[string]
  types*: seq[string]
  xmlLine*: int

type ExtensionData* = object
  deprecatedBy*: string
  isDeprecated*: bool = false
  name*: string
  number*: string
  obsoletedBy*: string
  platform*: string
  promotedTo*: string
  depends*: OrderedTable[string, seq[seq[string]]]
  requireData*: seq[RequireData]
  `type`*: string
  xmlLine*: int = 0

type FeatureData* = object
  name*: string
  api*: seq[string]
  number*: string
  removeData*: seq[RemoveData]
  requireData*: seq[RequireData]
  xmlLine*: int

type ExternalTypeData* = object
  require*: string
  xmlLine*: int

type ComponentData* = object
  bits*: string
  name*: string
  numericFormat*: string
  planeIndex*: string
  xmlLine*: int

type PlaneData* = object
  compatible*: string
  heightDivisor*: string
  widthDivisor*: string
  xmlLine*: int

type FormatData* = object
  blockExtent*: string
  blockSize*: string
  chroma*: string
  classAttribute*: string
  components*: seq[ComponentData]
  compressed*: string
  packed*: string
  planes*: seq[PlaneData]
  spirvImageFormat*: string
  texelsPerBlock*: string
  xmlLine*: int

type FuncPointerArgumentData* = object
  name*: string
  `type`*: string
  xmlLine*: int

type FuncPointerData* = object
  arguments*: seq[FuncPointerArgumentData]
  require*: string
  xmlLine*: int

type HandleData* = object
  childrenHandles*: OrderedSet[string]
  commands*: OrderedSet[string]
  deleteCommand*: string
  deleteParent*: string
  deletePool*: string
  objTypeEnum*: string
  parent*: string
  secondLevelCommands*: OrderedSet[string]
  isDispatchable*: bool
  xmlLine*: int

  # RAII data
  #destructorIt*: map<string, CommandData>::const_iterator
  #constructorIts*: vector<map<string, CommandData>::const_iterator>

type IncludeData* = object
  xmlLine*: int

type PlatformData* = object
  protect*: string
  comment*: string
  xmlLine*: int

type MemberData* = object
  `type`*: TypeInfo
  name*: string
  arraySizes*: seq[string]
  bitCount*: string
  lenExpressions*: seq[string]
  lenMembers*: seq[(string, csize_t)]
  noAutoValidity*: bool
  optional*: seq[bool]
  selection*: seq[string]
  selector*: string
  value*: string
  xmlLine*: int

type StructureData* = object
  allowDuplicate*: bool
  isUnion*: bool
  returnedOnly*: bool
  mutualExclusiveLens*: bool
  members*: seq[MemberData]
  structExtends*: seq[string]
  subStruct*: string
  xmlLine*: int

type TagData* = object
  xmlLine*: int
  author*: string
  contact*: string

type VectorParamData* = object
  lenParam*: csize_t = -1
  strideParam*: csize_t = -1

type MacroData* = tuple
  deprecatedComment: string
  calleeMacro: string
  params: seq[string]
  definition: string


type Registry * = object
  api                   *:string
  baseTypes             *:OrderedTable[string, BaseTypeData]
  bitmaskAliases        *:OrderedTable[string, AliasData]
  bitmasks              *:OrderedTable[string, BitmaskData]
  commandAliases        *:OrderedTable[string, AliasData]
  commands              *:OrderedTable[string, CommandData]
  constantAliases       *:OrderedTable[string, AliasData]
  constants             *:OrderedTable[string, ConstantData]
  defines               *:OrderedTable[string, DefineData]
  definesPartition      *:DefinesPartition  # partition defined macros into mutually-exclusive sets of callees, callers, and values
  enumAliases           *:OrderedTable[string, AliasData]
  enums                 *:OrderedTable[string, EnumData]
  extendedStructs       *:OrderedSet[string]
  extensions            *:seq[ExtensionData]
  externalTypes         *:OrderedTable[string, ExternalTypeData]
  features              *:seq[FeatureData] #Done
  formats               *:OrderedTable[string, FormatData] #Done
  funcPointers          *:OrderedTable[string, FuncPointerData]
  handleAliases         *:OrderedTable[string, AliasData]
  handles               *:OrderedTable[string, HandleData]
  includes              *:OrderedTable[string, IncludeData]
  platforms             *:OrderedTable[string, PlatformData] #Done
  RAIISpecialFunctions  *:OrderedSet[string]
  structAliases         *:OrderedTable[string, AliasData]
  structs               *:OrderedTable[string, StructureData]
  tags                  *:OrderedTable[string, TagData] #Done
  types                 *:OrderedTable[string, TypeData]
  typesafeCheck         *:string
  unsupportedExtensions *:OrderedSet[string]
  unsupportedFeatures   *:OrderedSet[string]
  version               *:string
  vulkanLicenseHeader   *:string

type Generator * = object
  doc *:XmlNode
  api *:string ## needs to be of value "vulkan" or "vulkansc"
  registry*: Registry

