# std dependencies
import std/strformat
import std/re
import std/strutils
# Generator dependencies
import ../customxmlParsing/xmltree
import ./common
import ../helpers
import options

proc parseDefineMacro*(node: XmlNode): MacroData =
  # [TODO] Actually parse define macros
  return MacroData()

proc readNameAndType *(node: XmlNode): (NameData, TypeInfo) =
  ## Extracts <name></name> and <type></type> from certain elements
  var name: NameData
  var typeInfo: TypeInfo
  for index, enumNameType in node:
    if enumNameType.kind != xnElement: continue
    case enumNameType.tag:
      of "enum":
        name.arraySizes.add(enumNameType.innerText)
      of "name":
        name.name = enumNameType.innerText().removeExtraSpace()
      of "type":
        typeInfo.prefix = node[index-1].innerText().removeExtraSpace()
        typeInfo.type = enumNameType.innerText().removeExtraSpace()
        typeInfo.postfix = node[index+1].innerText().removeExtraSpace() #They trim stars?
      else:
        discard
  return (name,typeInfo)

proc readTypeBase *(gen :var Generator, basetype :XmlNode) :void=
  var baseTypeData: BaseTypeData
  let nameOption = option(basetype.child("name"))
  assert nameOption.isSome
  let (name, typeinfo) = readNameAndType(basetype)
  baseTypeData.typeInfo = typeinfo
  baseTypeData.xmlLine = basetype.lineNumber
  if gen.registry.baseTypes.containsOrIncl(name.name,baseTypeData):
    duplicateAddError("Basetype",name.name,basetype.lineNumber)
proc readTypeBitmask *(gen :var Generator, bitmask :XmlNode) :void=
  let lineNumber = bitmask.lineNumber
  let alias = bitmask.attr("alias")
  if(alias != ""):
    let name = bitmask.attr("name")
    if gen.registry.bitmaskAliases.containsOrIncl(name, AliasData(name: alias, xmlLine: lineNumber)):
      duplicateAddError("BitmaskAlias",name,lineNumber)
  else:
    let requires = bitmask.attr("requires")
    let api = bitmask.attr("requires")
    let (name, typeinfo) = readNameAndType(bitmask)
    if api == "" or api == gen.api:
      if gen.registry.bitmasks.containsOrIncl(name.name,BitmaskData(require: requires, `type`: typeinfo.`type`, xmlLine: lineNumber)):
        duplicateAddError("Bitmask",name.name,lineNumber)
proc readTypeDefine *(gen :var Generator, define :XmlNode) :void=
  # type DefineData* = object
  #   deprecated*: bool = false
  #   require*: string
  #   xmlLine*: int
  #   deprecationReason*: string
  #   possibleCallee*: string
  #   params*: seq[string]
  #   possibleDefinition*: string
  var name: string = define.attr("name")
  let lineNumber: int = define.lineNumber
  let require: string = define.attr("requires")
  let api: string = define.attr("api")
  let deprecated: bool = define.attr("deprecated") == "true"
  var deprecationReason: seq[string]
  deprecationReason.setLen(1) #Memory has to be set beforehand. If memory isn't there it will fail
  if deprecated:
    if define.innerText().find(re"// DEPRECATED: (.*)\n",deprecationReason) == -1 and deprecationReason.len == 1:
      raise newException(ParsingError, "Wasn't able to find Depreciation reason for line: " & $lineNumber)
  if name != "":
    if name == "VK_USE_64_BIT_PTR_DEFINES":
      gen.registry.typesafeCheck = "#if ( VK_USE_64_BIT_PTR_DEFINES == 1 )"
    elif name == "VK_DEFINE_NON_DISPATCHABLE_HANDLE" and gen.registry.typesafeCheck != "":
      discard
  elif define.innerText() != "":
    # [TODO?] There are some struct typedef we could move to gen.reg.types
    name = define.child("name").innerText().removeExtraSpace()
    if name == "VK_HEADER_VERSION" and (api == "" or api == gen.api):
      gen.registry.version = define.lastChild.rawText().removeExtraSpace()
  assert(name != "")

  if api == "" or api == gen.api:
    let macroData = parseDefineMacro(define)
    if gen.registry.defines.containsOrIncl(name, DefineData(
      deprecated: deprecated,
      require: require,
      xmlLine: lineNumber,
      deprecationReason: deprecationReason[0],
      possibleCallee: macroData.possibleCalle,
      params: macroData.params,
      possibleDefinition: macroData.possibleDefinition,
    )):
      duplicateAddError("Define",name,lineNumber)

  discard

proc readTypeEnum *(gen :var Generator, types :XmlNode) :void=discard
proc readTypeFuncPointer *(gen :var Generator, types :XmlNode) :void=discard
proc readTypeHandle *(gen :var Generator, types :XmlNode) :void=discard
proc readTypeInclude *(gen :var Generator, types :XmlNode) :void=discard
proc readTypeStructOrUnion *(gen :var Generator, types :XmlNode) :void=discard

proc readTypes *(gen :var Generator, types :XmlNode) :void=
  for `type` in types:
    if `type`.tag == "type":
      let category = `type`.attr("category")
      if category != "":
        case category:
          of "basetype":
            gen.readTypeBase(`type`)
          of "bitmask":
            gen.readTypeBitmask(`type`)
          of "define":
            gen.readTypeDefine(`type`)
          of "enum":
            gen.readTypeEnum(`type`)
          of "funcpointer":
            gen.readTypeFuncPointer(`type`)
          of "handle":
            gen.readTypeHandle(`type`)
          of "include":
            gen.readTypeInclude(`type`)
          of "struct", "union":
            gen.readTypeStructOrUnion(`type`)
          else:
            raise newException(ParsingError,"Can not identify category of type: " & category)
      else:
        let requires = `type`.attr("requires").removeExtraSpace()
        if gen.registry.externalTypes.containsOrIncl(`type`.attr("name").removeExtraSpace(),ExternalTypeData(require: requires, xmlLine: `type`.lineNumber)):
          duplicateAddError("externalTypes",`type`.attr("name"),`type`.lineNumber)

proc generateTypesFile *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_types.nim"
  const genTemplate = """
#[
=====================================

Types

=====================================
]#
"""
  writeFile(outputDir,fmt genTemplate)

