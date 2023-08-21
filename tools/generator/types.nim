# std dependencies
import std/strformat
import ../customxmlParsing/xmltree
# Generator dependencies
import ./common
import ../helpers
import options

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
    duplicateAdd("Basetype",name.name,basetype.lineNumber)
proc readTypeBitmask *(gen :var Generator, bitmask :XmlNode) :void=
  let lineNumber = bitmask.lineNumber
  let alias = bitmask.attr("alias")
  if(alias != ""):
    let name = bitmask.attr("name")
    if gen.registry.bitmaskAliases.containsOrIncl(name, AliasData(name: alias, xmlLine: lineNumber)):
      duplicateAdd("BitmaskAlias",name,lineNumber)
  else:
    let requires = bitmask.attr("requires")
    let api = bitmask.attr("requires")
    let (name, typeinfo) = readNameAndType(bitmask)
    if api == "" or api == gen.api:
      if gen.registry.bitmasks.containsOrIncl(name.name,BitmaskData(require: requires, `type`: typeinfo.`type`, xmlLine: lineNumber)):
        duplicateAdd("Bitmask",name.name,lineNumber)
proc readTypeDefine *(gen :var Generator, types :XmlNode) :void=discard
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
          duplicateAdd("externalTypes",`type`.attr("name"),`type`.lineNumber)

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

