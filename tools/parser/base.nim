#___________________________________________________________
# Base functionality required for all files
#_______________________________________
# Contains the type definitions required by everything, to avoid cyclic dependencies
# I always call this `types` and `base (for procs)`, instead of `base (for types)` and `common (for procs)`
# but that naming scheme conflicts with the existing `types` file for the generator, refering to Vulkan types.
#___________________________________________________________
# std dependencies
import std/strformat ; export strformat
import std/strutils  ; export strutils
import std/tables    ; export tables
import std/sets      ; export sets
import std/strtabs   ; export strtabs
import std/options   ; export options
# External dependencies
import regex         ; export regex
# Generator dependencies
import ../customxml   ; export customxml
import ../helpers     ; export helpers

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
  category   *: TypeCategory = TypeCategory.Unknown
  requiredBy *: OrderedSet[string]
  xmlLine    *: int

type TypeInfo* = object
  prefix  *:string
  `type`  *:string
  postfix *:string


type BaseTypeData* = object
  typeInfo  *:TypeInfo
  xmlLine   *:int

type AliasData * = object
  name       *:string
  deprecated *:string  # Information for adding the {.deprecated: reason.} pragma. Contained in the XML, useful for nim too
  api        *:string  # Known values: "vulkan" and "vulkansc"
  xmlLine    *:int

type ConstantData* = object
  typ      *:string
  value    *:string
  xmlLine  *:int

type BitmaskValueData * = object
  isValue  *:bool    # Marks the bitmask as being a preset value (eg: FLAG1 | FLAG2 | FLAG3 )
  value    *:string  # Stores the value of the bitflags group represented by this entry. Maps to a separate template in nim (unlike in C)
  bitpos   *:string
  comment  *:string
  protect  *:string  # Only bitmask values added by the Extensions section have this field active. Not in the main list.
  xmlLine  *:int

type BitmaskData * = object
  comment   *:string
  bitwidth  *:string
  require   *:string  # Not used in the main enum-bitmask list. Added only in the types section.
  typ       *:string
  values    *:OrderedTable[string, BitmaskValueData]
  xmlLine   *:int
  bitvalues *:string

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

type NameData* = object
  name*: string
  arraySizes*: seq[string]


type ProtoData * = object
  name           *:string
  typ            *:string
  xmlLine        *:int

type ImplicitExternSyncParamsData * = object
  param          *:seq[string]
  xmlLine        *:int

type ParamTypeInfo * = object
  prefix  *:string
  typ     *:string
  postfix *:string
  name    *:string

type ParamData * = object
  optional       *:seq[string]
  externsync     *:seq[string]
  noautovalidity *:bool
  stride         *:string
  objecttype     *:string
  altlen         *:string
  api            *:seq[string]
  length         *:string
  validstructs   *:string
  isObject       *:bool
  typ            *:ParamTypeInfo
  xmlLine        *:int
  #???????????????????????????????
  # arraySizes     *:seq[string]
  #???????????????????????????????

type CommandData * = object
  errorCodes     *:seq[string]
  successCodes   *:seq[string]
  api            *:string
  queues         *:seq[string]
  cmdbufferlevel *:seq[string]
  tasks          *:seq[string]
  renderpass     *:string
  comment        *:string
  videocoding    *:string
  proto          *:ProtoData  # Single Proto definition for entry
  params         *:seq[ParamData]
  asyncParams    *:ImplicitExternSyncParamsData
  xmlLine        *:int
  #???????????????????????????????
  # handle       *:string
  # requiredBy   *:OrderedSet[string]
  # returnType   *:string
  #???????????????????????????????

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
  comment  *:string
  commands *:seq[string]
  enums    *:seq[string]
  types    *:seq[string]
  xmlLine  *:int

type EnumFeatureData * = object
  extends   *:string
  extnumber *:string
  offset    *:string
  bitpos    *:string
  alias     *:string
  dir       *:string
  api       *:string
  value     *:string
  xmlLine   *:int

type RequireData * = object
  depends   *:seq[string]
  api       *:seq[string]
  comment   *:string
  missing   *:seq[string] # Information about missing entries that are listed as an infix comment instead.
  commands  *:seq[string]
  constants *:OrderedTable[string, EnumFeatureData]
  types     *:seq[string]
  xmlLine   *:int


type RequireEnumData * = object
  name       *:string
  comment    *:string
  value      *:string
  extends    *:string
  offset     *:int
  dir        *:string
  extnumber  *:int
  bitpos     *:string
  alias      *:string
  deprecated *:string
  api        *:seq[string]
  protect    *:string
  xmlLine    *:int

type RequireTypeData * = object
  comment    *:string
  xmlLine    *:int

type RequireCommandData * = object
  comment    *:string
  xmlLine    *:int


type ExtensionRequireData * = object
  depends   *:seq[string]
  api       *:seq[string]
  comment   *:string
  enums     *:seq[RequireEnumData]
  types     *:OrderedTable[string, RequireTypeData]
  commands  *:OrderedTable[string, RequireCommandData]
  xmlLine   *:int

type ExtensionData* = object
  supported    *:seq[string]
  contact      *:string
  typ          *:string
  number       *:string
  ratified     *:seq[string]
  author       *:string
  depends      *:string  # depends *:OrderedTable[string, seq[seq[string]]]
  platform     *:string
  comment      *:string
  specialuse   *:seq[string]
  deprecatedby *:string
  promotedTo   *:string
  obsoletedBy  *:string
  provisional  *:bool
  sortorder    *:string
  requireData  *:seq[ExtensionRequireData]
  xmlLine      *:int

type FeatureData* = object
  name        *:string
  comment     *:string
  number      *:string
  api         *:seq[string]
  removeData  *:seq[RemoveData]
  requireData *:seq[RequireData]
  xmlLine     *:int

type ExternalTypeData* = object
  require *:string
  xmlLine *:int

type ComponentData * = object
  bits          *:string
  numericFormat *:string
  planeIndex    *:string
  xmlLine       *:int

type PlaneData * = object
  index         *:string
  compatible    *:string
  heightDivisor *:string
  widthDivisor  *:string
  xmlLine       *:int

type FormatData * = object
  class            *:string
  blockExtent      *:string
  blockSize        *:string
  chroma           *:string
  classAttribute   *:string
  components       *:OrderedTable[string, ComponentData]
  compressed       *:string
  packed           *:string
  planes           *:OrderedTable[string, PlaneData]
  spirvImageFormat *:string
  texelsPerBlock   *:string
  xmlLine          *:int

type FuncPointerArgumentData* = object
  name*: string
  `type`*: string
  isPtr*: bool
  xmlLine*: int

type FuncPointerData* = object
  arguments*: seq[FuncPointerArgumentData]
  require*: string
  `type`*: string
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
  lenMembers*: seq[(string, int)]
  noAutoValidity*: bool
  optional*: seq[bool]
  selection*: seq[string]
  selector*: string
  value*: string
  limitType*: seq[string]
  deprecated*: bool
  objectType*: string
  externSync*: bool
  api*: string
  xmlLine*: int

type StructureData * = object
  allowDuplicate      *:bool
  isUnion             *:bool
  returnedOnly        *:bool
  mutualExclusiveLens *:bool
  members             *:seq[MemberData]
  structExtends       *:seq[string]
  subStruct           *:string
  xmlLine             *:int

type TagData* = object
  xmlLine*: int
  author*: string
  contact*: string

type VectorParamData* = object
  lenParam*: csize_t = 0
  strideParam*: csize_t = 0

type MacroData* = tuple
  deprecatedComment: string
  calleeMacro: string
  params: seq[string]
  definition: string

type CommentData * = object
  text    *:string
  xmlLine *:int

type SyncSupportData * = object
  queues  *:string
  stage   *:string
  xmlLine *:int

type SyncEquivalentData * = object
  stage   *:string
  access  *:string
  xmlLine *:int

type SyncStageData * = object
  alias       *:string
  support     *:OrderedTable[string, SyncSupportData]
  equivalent  *:OrderedTable[string, SyncEquivalentData]
  xmlLine     *:int

type SyncAccessData * = object
  alias       *:string
  support     *:OrderedTable[string, SyncSupportData]
  equivalent  *:OrderedTable[string, SyncEquivalentData]
  comment     *:string
  xmlLine     *:int

type SyncPipelineStageData * = object
  order       *:string
  before      *:string
  xmlLine     *:int

type SyncPipelineData * = object
  alias       *:string
  depends     *:string
  stage       *:seq[SyncPipelineStageData]
  xmlLine     *:int

type SyncData * = object
  comment   *:string
  stages    *:OrderedTable[string, SyncStageData]
  access    *:OrderedTable[string, SyncAccessData]
  pipelines *:OrderedTable[string, SyncPipelineData]
  xmlLine   *:int

type SpirvCapEnableData * = object
  version   *:string
  feature   *:string
  requires  *:string
  struct    *:string
  extension *:string
  member    *:string
  property  *:string
  value     *:string
  alias     *:string
  xmlLine   *:int

type SpirvExtEnableData * = object
  version   *:string
  extension *:string
  xmlLine   *:int

type SpirvCapData * = object
  enable  *:seq[SpirvCapEnableData]
  xmlLine *:int

type SpirvExtData * = object
  enable  *:seq[SpirvExtEnableData]
  xmlLine *:int

type Registry * = object
  api                   *:string
  baseTypes             *:OrderedTable[string, BaseTypeData]
  bitmaskAliases        *:OrderedTable[string, AliasData]
  bitmasks              *:OrderedTable[string, BitmaskData]
  commandAliases        *:OrderedTable[string, AliasData]
  commands              *:seq[CommandData]
  constantAliases       *:OrderedTable[string, AliasData]
  constants             *:OrderedTable[string, ConstantData]
  defines               *:OrderedTable[string, DefineData]
  definesPartition      *:DefinesPartition  # partition defined macros into mutually-exclusive sets of callees, callers, and values
  enumAliases           *:OrderedTable[string, AliasData]
  enums                 *:OrderedTable[string, EnumData]
  extendedStructs       *:OrderedSet[string]
  extensions            *:OrderedTable[string, ExtensionData]
  externalTypes         *:OrderedTable[string, ExternalTypeData]
  features              *:seq[FeatureData]
  formats               *:OrderedTable[string, FormatData]
  funcPointers          *:OrderedTable[string, FuncPointerData]
  handleAliases         *:OrderedTable[string, AliasData]
  handles               *:OrderedTable[string, HandleData]
  includes              *:OrderedTable[string, IncludeData]
  platforms             *:OrderedTable[string, PlatformData]
  RAIISpecialFunctions  *:OrderedSet[string]
  structAliases         *:OrderedTable[string, AliasData]
  structs               *:OrderedTable[string, StructureData]
  types                 *:OrderedTable[string, TypeData]
  tags                  *:OrderedTable[string, TagData]
  sync                  *:SyncData
  spirvCapabilities     *:OrderedTable[string, SpirvCapData]
  spirvExtensions       *:OrderedTable[string, SpirvExtData]
  typesafeCheck         *:string
  unsupportedExtensions *:OrderedSet[string]
  unsupportedFeatures   *:OrderedSet[string]
  version               *:string
  vulkanLicenseHeader   *:string
  rootComments          *:seq[CommentData]
  requires              *:OrderedTable[string, RequireData]


type Parser * = object
  doc      *:XmlNode
  api      *:string  ## needs to be of value "vulkan" or "vulkansc"
  registry *:Registry