# Generator dependencies
import ./common

proc parseDefineMacro*(define: XmlNode): MacroData =
  ## parses macros from the spec
  # TODO Actually parse define macros
  # TODO ensure proper error handling
  let paramsRegex  = re2"(\(.*?\))"
  let commentRegex = re2"(\s*//.*)"
  let text = define.innerText()
  var depreciationMatch: RegexMatch2
  var deprecationReason: string
  deprecationReason.setLen(1) #Memory has to be set beforehand. If memory isn't there it will fail
  if text.find(re2"// DEPRECATED: (.*)\n",depreciationMatch):
    deprecationReason = text[depreciationMatch.captures[0]]

  if define.len == 3:
    var paramsAndDefinitionAndTrailingComment = define[2].innerText().strip().removeSlashNewLine().removeExtraSpace()
    if not paramsAndDefinitionAndTrailingComment.contains("("):
      #No parameters found
      return (deprecationReason,"",@[],paramsAndDefinitionAndTrailingComment.replace(commentRegex,""))
    var argMatch: RegexMatch2
    var args : seq[string] = @[""]
    if paramsAndDefinitionAndTrailingComment.find(paramsRegex,argMatch):
      args = paramsAndDefinitionAndTrailingComment[argMatch.captures[0]].removePrefix("(").removeSuffix(")").split(", ")
    var implementation = paramsAndDefinitionAndTrailingComment.replace(paramsRegex,"",1).replace(commentRegex,"")
    return (deprecationReason,"",args,implementation)
  elif define.len == 4:
    let
      calledMacro: string = define[2].innerText().removePrefix("VK_").change(SCREAM_CASE, camelCase)
      argsAndTrailingComment: string = define[3].innerText()
    var argMatch: RegexMatch2
    var args : seq[string] = @[""]
    if argsAndTrailingComment.find(paramsRegex,argMatch):
      args = argsAndTrailingComment[argMatch.captures[0]].removePrefix("(").removeSuffix(")").split(", ")
    return (deprecationReason,calledMacro,args,"")
  return (deprecationReason,"",@[],"")

proc readNameAndType *(node: XmlNode): (NameData, TypeInfo) =
  ## Extracts <name></name> and <type></type> from certain elements
  # TODO ensure this has error handling
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
        if(index-1 > 0):
          typeInfo.prefix = node[index-1].innerText().removeExtraSpace()
        typeInfo.type = enumNameType.innerText().removeExtraSpace()
        if(index+1 < node.len):
          typeInfo.postfix = node[index+1].innerText().removeExtraSpace() #They trim stars?
      else:
        discard
  return (name,typeInfo)

proc readTypeBase *(gen :var Generator, basetype :XmlNode) :void=
  basetype.checkKnownKeys(BaseTypeData, ["category"])
  basetype.checkKnownNodes(BaseTypeData,["name","type"])
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
    bitmask.checkKnownKeys(AliasData, ["name","alias","category"])
    let name = bitmask.attr("name")
    if gen.registry.bitmaskAliases.containsOrIncl(name, AliasData(name: alias, xmlLine: lineNumber)):
      duplicateAddError("BitmaskAlias",name,lineNumber)
  else:
    bitmask.checkKnownKeys(BitmaskData, ["api", "requires","category","bitvalues"])
    bitmask.checkKnownNodes(BitmaskData,["name","type"])
    let requires = bitmask.attr("requires")
    let api = bitmask.attr("api")
    let bitvalues = bitmask.attr("bitvalues")
    let (name, typeinfo) = readNameAndType(bitmask)
    if api == "" or api == gen.api:
      if gen.registry.bitmasks.containsOrIncl(name.name,BitmaskData(require: requires, typ: typeinfo.`type`, xmlLine: lineNumber, bitvalues: bitvalues)):
        duplicateAddError("Bitmask",name.name,lineNumber)
proc readTypeDefine *(gen :var Generator, define :XmlNode) :void=
  define.checkKnownKeys(DefineData, ["name", "requires", "deprecated", "category", "api", "comment"])
  var name: string = define.attr("name")
  let lineNumber: int = define.lineNumber
  let require: string = define.attr("requires")
  let api: string = define.attr("api")
  let deprecated: bool = define.attr("deprecated") == "true"
  if name != "":
    if name == "VK_USE_64_BIT_PTR_DEFINES":
      gen.registry.typesafeCheck = "#if ( VK_USE_64_BIT_PTR_DEFINES == 1 )"
    elif name == "VK_DEFINE_NON_DISPATCHABLE_HANDLE" and gen.registry.typesafeCheck != "":
      discard
  elif define.innerText() != "":
    # [TODO?] There are some struct typedef we could move to gen.reg.types
    name = define.child("name").innerText().removeExtraSpace()
    if name == "VK_HEADER_VERSION" and (api == "" or api == gen.api):
      gen.registry.version = define.lastChild().innerText().removeExtraSpace()
  assert(name != "")

  if api == "" or api == gen.api:
    let (deprecationReason, possibleCallee, params, possibleDefinition) = parseDefineMacro(define)
    if gen.registry.defines.containsOrIncl(name, DefineData(
      deprecated: deprecated,
      require: require,
      xmlLine: lineNumber,
      deprecationReason: deprecationReason,
      possibleCallee: possibleCallee,
      params: params,
      possibleDefinition: possibleDefinition,
    )):
      duplicateAddError("Define",name,lineNumber)

proc readTypeEnum *(gen :var Generator, enumNode :XmlNode) :void=
  enumNode.checkKnownKeys(AliasData, ["name", "alias", "category"])
  enumNode.checkKnownNodes(AliasData,[])
  let name = enumNode.attr("name")
  let alias = enumNode.attr("alias")

  if alias != "":
    if gen.registry.enumAliases.containsOrIncl(name,AliasData(name: alias,xmlline: enumNode.lineNumber)):
      duplicateAddError("Enum Alias",name,enumNode.lineNumber)

proc readTypeFuncPointer *(gen :var Generator, funcPointer :XmlNode) :void=
  funcPointer.checkKnownKeys(FuncPointerData, ["requires", "category"], KnownEmpty=[])
  funcPointer.checkKnownNodes(FuncPointerData,["name","type"])
  let
    requires: string = funcPointer.attr("requires")
    lineNumber: int = funcPointer.lineNumber
  var
    name: string
    arguments: seq[FuncPointerArgumentData]
    argMatch: RegexMatch2
  let typedefRegex = re2"typedef\s(.*[^\s]) \("
  let typedeftext = funcPointer[0].innerText()
  var funcptrtype: string
  if(typedeftext.find(typedefRegex,argMatch)):
    assert(argMatch.captures.len == 1)
    funcptrtype = typedeftext[argMatch.captures[0]]
  assert(funcptrtype != "")

  for index, child in funcPointer:
    if child.kind == xnText:
      discard #needed to prevent errors calling .tag on non element
    elif child.tag == "name":
      name = child.innerText()
    elif child.tag == "type":
      let `type` = child.innerText()
      let lineNumber = child.lineNumber
      let nametext = funcPointer[index+1].innerText().removeExtraSpace()
      let nameptrRegex: Regex2 = re2"(?P<ptr>\**) *(?P<name>\w+)"
      var nameptrMatch: RegexMatch2
      if(nametext.find(nameptrRegex,nameptrMatch)):
        assert(nameptrMatch.captures.len > 0 and nameptrMatch.captures.len <= 2)
        let isPtr = nametext[nameptrMatch.group("ptr")] == "*"
        let name = nametext[nameptrMatch.group("name")]
        assert(name != "")
        arguments.add(FuncPointerArgumentData(name: name, `type`: `type`, isPtr: isPtr, xmlline: lineNumber))
  assert(name != "")
  if gen.registry.funcPointers.containsOrIncl(name,FuncPointerData(arguments: arguments, require: requires, `type`: funcptrtype, xmlline: lineNumber)):
      duplicateAddError("FuncPointer",name,lineNumber)

proc readTypeHandle *(gen :var Generator, handle :XmlNode) :void=
  # childrenHandles*: OrderedSet[string]
  # commands*: OrderedSet[string]
  # deleteCommand*: string
  # deleteParent*: string
  # deletePool*: string
  # objTypeEnum*: string
  # parent*: string
  # secondLevelCommands*: OrderedSet[string]
  # isDispatchable*: bool
  # xmlLine*: int
  handle.checkKnownKeys(HandleData, ["name","parent", "category", "alias", "objtypeenum"], KnownEmpty=[])
  handle.checkKnownNodes(HandleData,["name","type"])
  let
    alias = handle.attr("alias")
    lineNumber = handle.lineNumber

  if (alias != ""):
    let name = handle.attr("name")
    assert(name != "")
    if gen.registry.handleAliases.containsOrIncl(name,AliasData(name: alias, xmlLine: lineNumber)):
      duplicateAddError("TypeHandle",name,lineNumber)
  else:
    let
      parent = handle.attr("parent")
      objtypeenum = handle.attr("objtypeenum")
      (name, typeInfo) = readNameAndType(handle)
    assert(objtypeenum != "")
    assert(name.name != "" and typeInfo.`type` != "")
    let isDispatchable = typeInfo.`type` == "VK_DEFINE_HANDLE"
    if gen.registry.types.containsOrIncl(name.name,TypeData(category: TypeCategory.Handle,xmlLine: lineNumber)):
      duplicateAddError("TypeData",name.name,lineNumber)
    if gen.registry.handles.containsOrIncl(name.name, HandleData(parent: parent, objTypeEnum: objTypeEnum, isDispatchable: isDispatchable, xmlLine: lineNumber)):
      duplicateAddError("HandleData",name.name,lineNumber)

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
          of "":
            # TODO Requires type notation <type requires="X11/Xlib.h" name="Display"/>
            discard
          else:
            raise newException(ParsingError,"Can not identify category of type: " & category)
      else:
        let requires = `type`.attr("requires").removeExtraSpace()
        if gen.registry.externalTypes.containsOrIncl(`type`.attr("name").removeExtraSpace(),ExternalTypeData(require: requires, xmlLine: `type`.lineNumber)):
          duplicateAddError("externalTypes",`type`.attr("name"),`type`.lineNumber)

proc generateTypes *(gen :Generator) :void=
  let outputDir = fmt"./src/VulkanNim/{gen.api}_types.nim"
  const genTemplate = """
#[
=====================================

Types

=====================================
]#
"""
  writeFile(outputDir,fmt genTemplate)

