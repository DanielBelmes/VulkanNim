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
        if(index+1 < node.len):
          let arraySizeReg = re2"\[(\d+)\]" #TODO: I don't have to use regex but I am lazy
          var arraySizeMatch: RegexMatch2
          let text = node[index+1].innerText()
          if (text.find(arraySizeReg, arraySizeMatch)):
            name.arraySizes.add(text[arraySizeMatch.captures[0]])
        name.name = enumNameType.innerText().removeExtraSpace()
      of "type":
        if(index-1 >= 0):
          typeInfo.prefix = node[index-1].innerText().removeExtraSpace()
        typeInfo.type = enumNameType.innerText().removeExtraSpace()
        if(index+1 < node.len):
          if(node[index+1].kind == xnElement): continue
          typeInfo.postfix = node[index+1].innerText().removeExtraSpace() #They trim stars?
      else:
        discard
  return (name,typeInfo)

proc readTypeBase *(parser :var Parser, basetype :XmlNode) :void=
  basetype.checkKnownKeys(BaseTypeData, ["category"])
  basetype.checkKnownNodes(BaseTypeData,["name","type"])
  var baseTypeData: BaseTypeData
  var typeData: TypeData
  typeData.category = TypeCategory.BaseType
  let nameOption = option(basetype.child("name"))
  assert nameOption.isSome
  let (name, typeinfo) = readNameAndType(basetype)
  baseTypeData.typeInfo = typeinfo
  baseTypeData.xmlLine = basetype.lineNumber
  typeData.xmlLine = basetype.lineNumber
  if parser.registry.baseTypes.containsOrIncl(name.name,baseTypeData):
    duplicateAddError("Basetype",name.name,basetype.lineNumber)
  if parser.registry.types.containsOrIncl(name.name,typeData):
    duplicateAddError("type",name.name,basetype.lineNumber)
proc readTypeBitmask *(parser :var Parser, bitmask :XmlNode) :void=
  let lineNumber = bitmask.lineNumber
  let alias = bitmask.attr("alias")
  if(alias != ""):
    bitmask.checkKnownKeys(AliasData, ["name","alias","category"])
    let name = bitmask.attr("name")
    if parser.registry.types.containsOrIncl(name,TypeData(category: TypeCategory.Bitmask,xmlLine: lineNumber)):
      duplicateAddError("BitmaskAlias",name,lineNumber)
    if parser.registry.bitmaskAliases.containsOrIncl(name, AliasData(name: alias, xmlLine: lineNumber)):
      duplicateAddError("BitmaskAlias",name,lineNumber)
  else:
    bitmask.checkKnownKeys(BitmaskData, ["api", "requires","category","bitvalues"])
    bitmask.checkKnownNodes(BitmaskData,["name","type"])
    let requires = bitmask.attr("requires")
    let api = bitmask.attr("api")
    let bitvalues = bitmask.attr("bitvalues")
    let (name, typeinfo) = readNameAndType(bitmask)
    if api == "" or api == parser.api:
      if parser.registry.types.containsOrIncl(name.name,TypeData(category: TypeCategory.Bitmask,xmlLine: lineNumber)):
        duplicateAddError("Bitmask",name.name,lineNumber)
      if parser.registry.bitmasks.containsOrIncl(name.name,BitmaskData(require: requires, typ: typeinfo.`type`, xmlLine: lineNumber, bitvalues: bitvalues)):
        duplicateAddError("Bitmask",name.name,lineNumber)
proc readTypeDefine *(parser :var Parser, define :XmlNode) :void=
  define.checkKnownKeys(DefineData, ["name", "requires", "deprecated", "category", "api", "comment"])
  var name: string = define.attr("name")
  let lineNumber: int = define.lineNumber
  let require: string = define.attr("requires")
  let api: string = define.attr("api")
  let deprecated: bool = define.attr("deprecated") == "true"
  if name != "":
    if name == "VK_USE_64_BIT_PTR_DEFINES":
      parser.registry.typesafeCheck = "#if ( VK_USE_64_BIT_PTR_DEFINES == 1 )"
    elif name == "VK_DEFINE_NON_DISPATCHABLE_HANDLE" and parser.registry.typesafeCheck != "":
      discard
  elif define.innerText() != "":
    # [TODO?] There are some struct typedef we could move to parser.reg.types
    name = define.child("name").innerText().removeExtraSpace()
    if name == "VK_HEADER_VERSION" and (api == "" or api == parser.api):
      parser.registry.version = define.lastChild().innerText().removeExtraSpace()
  assert(name != "")

  if api == "" or api == parser.api:
    if parser.registry.types.containsOrIncl(name,TypeData(category: TypeCategory.Define,xmlLine: lineNumber)):
      duplicateAddError("Define",name,lineNumber)
    let (deprecationReason, possibleCallee, params, possibleDefinition) = parseDefineMacro(define)
    if parser.registry.defines.containsOrIncl(name, DefineData(
      deprecated: deprecated,
      require: require,
      xmlLine: lineNumber,
      deprecationReason: deprecationReason,
      possibleCallee: possibleCallee,
      params: params,
      possibleDefinition: possibleDefinition,
    )):
      duplicateAddError("Define",name,lineNumber)

proc readTypeEnum *(parser :var Parser, enumNode :XmlNode) :void=
  enumNode.checkKnownKeys(AliasData, ["name", "alias", "category"])
  enumNode.checkKnownNodes(AliasData,[])
  let name = enumNode.attr("name")
  let alias = enumNode.attr("alias")
  let lineNumber = enumNode.lineNumber

  if parser.registry.types.containsOrIncl(name,TypeData(category: TypeCategory.Enum,xmlLine: lineNumber)):
    duplicateAddError("EnumType",name,lineNumber)

  if alias != "":
    if parser.registry.enumAliases.containsOrIncl(name,AliasData(name: alias,xmlline: lineNumber)):
      duplicateAddError("Enum Alias",name,lineNumber)

proc readTypeFuncPointer *(parser :var Parser, funcPointer :XmlNode) :void=
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
  if parser.registry.types.containsOrIncl(name,TypeData(category: TypeCategory.FuncPointer,xmlLine: lineNumber)):
    duplicateAddError("FuncPointer",name,lineNumber)
  if parser.registry.funcPointers.containsOrIncl(name,FuncPointerData(arguments: arguments, require: requires, `type`: funcptrtype, xmlline: lineNumber)):
      duplicateAddError("FuncPointer",name,lineNumber)

proc readTypeHandle *(parser :var Parser, handle :XmlNode) :void=
  handle.checkKnownKeys(HandleData, ["name","parent", "category", "alias", "objtypeenum"], KnownEmpty=[])
  handle.checkKnownNodes(HandleData,["name","type"])
  let
    alias = handle.attr("alias")
    lineNumber = handle.lineNumber

  if (alias != ""):
    let name = handle.attr("name")
    assert(name != "")
    if parser.registry.handleAliases.containsOrIncl(name,AliasData(name: alias, xmlLine: lineNumber)):
      duplicateAddError("TypeHandle",name,lineNumber)
  else:
    let
      parent = handle.attr("parent")
      objtypeenum = handle.attr("objtypeenum")
      (name, typeInfo) = readNameAndType(handle)
    assert(objtypeenum != "")
    assert(name.name != "" and typeInfo.`type` != "")
    let isDispatchable = typeInfo.`type` == "VK_DEFINE_HANDLE"
    if parser.registry.types.containsOrIncl(name.name,TypeData(category: TypeCategory.Handle,xmlLine: lineNumber)):
      duplicateAddError("TypeData",name.name,lineNumber)
    if parser.registry.handles.containsOrIncl(name.name, HandleData(parent: parent, objTypeEnum: objTypeEnum, isDispatchable: isDispatchable, xmlLine: lineNumber)):
      duplicateAddError("HandleData",name.name,lineNumber)

proc readTypeInclude *(parser :var Parser, includes :XmlNode) :void=
  includes.checkKnownKeys(HandleData, ["name","category"], KnownEmpty=[])
  includes.checkKnownNodes(HandleData,[])
  let name = includes.attr("name")
  let lineNumber = includes.lineNumber
  if parser.registry.types.containsOrIncl(name,TypeData(category: TypeCategory.Include,xmlLine: lineNumber)):
    duplicateAddError("IncludeData",name,lineNumber)
  if parser.registry.includes.containsOrIncl(name,IncludeData(xmlLine: lineNumber)):
    duplicateAddError("IncludeData",name,lineNumber)

proc filterNumbers(names: seq[string]): seq[(string, int)] =
  for name in names:
    if not name.contains(re2"\d") and name != "":
      result.add((name, 0))
proc determineSubStruct*(struct: XmlNode): string =
  discard
proc readTypeStructOrUnion *(parser :var Parser, structOrUnion :XmlNode) :void=
  structOrUnion.checkKnownKeys(StructureData, ["name","category","returnedonly","structextends","comment","allowduplicate","alias"])
  structOrUnion.checkKnownNodes(StructureData, ["member","comment"])
  let
    alias = structOrUnion.attr("alias")
    name = structOrUnion.attr("name")
    isUnion = structOrUnion.attr("category") == "union"
    allowDuplicate = structOrUnion.attr("allowduplicate") == "true"
    returnedOnly = structOrUnion.attr("returnedOnly") == "true"
    structextends = structOrUnion.attr("structextends").split(',')
    lineNumber = structOrUnion.lineNumber
  assert(name != "")
  if parser.registry.types.containsOrIncl(name,TypeData(category: if isUnion: TypeCategory.Union else: TypeCategory.Struct,xmlLine: lineNumber)):
    duplicateAddError("IncludeData",name,lineNumber)
  if alias != "":
    if parser.registry.structAliases.containsOrIncl(name,AliasData(name:alias,xmlLine:lineNumber)):
      duplicateAddError("Struct Alias",name,lineNumber)
  else:
    var
      members: seq[MemberData]
      structData = StructureData(allowDuplicate: allowDuplicate, returnedOnly: returnedOnly, isUnion: isUnion, structExtends: structExtends, subStruct: determineSubStruct(structOrUnion), xmlLine:lineNumber)
    for member in structOrUnion:
      if member.kind != xnElement: continue
      if member.tag != "member": continue
      var memberData = MemberData()
      member.checkKnownKeys(MemberData,["values","optional","noautovalidity","limittype","len","deprecated","altlen","api","objecttype","externsync","selection","selector"],["member"])
      member.checkKnownNodes(MemberData,["name","type","comment","enum"])
      let (name,typedata) = readNameAndType(member)
      memberData.name = name.name
      memberData.`type` = typedata
      memberData.arraySizes = name.arraySizes
      memberData.xmlLine = member.lineNumber
      if not member.attrs.isNil:
        for (attr, value) in member.attrs.pairs:
          if attr == "api":
            memberData.api = value
          elif attr == "altlen":
            memberData.lenExpressions = value.split(',')
            memberData.lenMembers = filterNumbers(value.split({' ','/','(',')','+','*'}))
          elif attr == "deprecated":
            memberData.deprecated = true
          elif attr == "len":
            memberData.lenExpressions = value.split(',')
            if memberData.lenExpressions[0] != "null-terminated":
              let structMemberIdx = members.find(proc (item: MemberData): bool = return item.name == memberData.lenExpressions[0])
              memberData.lenMembers.add((memberData.lenExpressions[0], structMemberIdx)) # I think this is right
          elif attr == "values":
            memberData.value = value
          elif attr == "objecttype":
            memberData.objectType = value
          elif attr == "externsync":
            memberData.externSync = value == "true"
          elif attr == "optional":
            let optionals = value.split(',')
            memberData.optional.setLen(optionals.len)
            for o in optionals:
              memberData.optional.add(true)
          elif attr == "noautovalidity":
            memberData.noAutoValidity = value == "true"
          elif attr == "selector":
            memberData.selector = value
          elif attr == "selection":
            memberData.selection = value.split(',')
          elif attr == "limittype":
            memberData.limitType = value.split(',')
      members.add(memberData)
    structData.members = members
    var
      warned = false
    const
      mutualExclusiveStructs: OrderedSet[string] = toOrderedSet(["VkAccelerationStructureBuildGeometryInfoKHR", "VkAccelerationStructureTrianglesOpacityMicromapEXT", "VkMicromapBuildInfoEXT", "VkWriteDescriptorSet"])
      multipleLenStructs: OrderedSet[string] = toOrderedSet(["VkAccelerationStructureTrianglesDisplacementMicromapNV",
                                                          "VkImageConstraintsInfoFUCHSIA",
                                                          "VkIndirectCommandsLayoutTokenNV",
                                                          "VkPresentInfoKHR",
                                                          "VkSemaphoreWaitInfo",
                                                          "VkSubmitInfo",
                                                          "VkSubpassDescription",
                                                          "VkSubpassDescription2",
                                                          "VkWin32KeyedMutexAcquireReleaseInfoKHR",
                                                          "VkWin32KeyedMutexAcquireReleaseInfoNV" ])
    for i0, member in members:
      if warned: break
      if(member.lenExpressions.len != 0 and member.lenExpressions[0] != "null-terminated"):
        for i1, member1 in members:
          if i0 == i1: continue
          if member1.lenExpressions.len != 0 and member.lenExpressions[0] == member1.lenExpressions[0]:
            if mutualExclusiveStructs.contains(member.name):
              structData.mutualExclusiveLens = true
            else:
              if not multipleLenStructs.contains(member.name):
                when defined(debug):
                  echo &"Encountered structure <:{$name}> with multiple members referencing the same member for len. Need to be checked if they are supposed to be mutually exclusive.\n"
              warned = true
    if parser.registry.structs.containsOrIncl(name,structData):
      duplicateAddError("Struct Alias",name,lineNumber)

proc readRequires *(parser :var Parser, requires :XmlNode) :void=
  requires.checkKnownKeys(StructureData, ["name","requires"])
  if parser.registry.requires.containsOrIncl(requires.attr("name"),RequireData(depends: @[requires.attr("requires")], xmlLine: requires.lineNumber)):
    duplicateAddError("Struct Alias",requires.attr("name"),requires.lineNumber)

proc readTypes *(parser :var Parser, types :XmlNode) :void=
  for `type` in types:
    if `type`.tag == "type":
      let category = `type`.attr("category")
      if category != "":
        case category:
          of "basetype"        : parser.readTypeBase(`type`)
          of "bitmask"         : parser.readTypeBitmask(`type`)
          of "define"          : parser.readTypeDefine(`type`)
          of "enum"            : parser.readTypeEnum(`type`)
          of "funcpointer"     : parser.readTypeFuncPointer(`type`)
          of "handle"          : parser.readTypeHandle(`type`)
          of "include"         : parser.readTypeInclude(`type`)
          of "struct", "union" : parser.readTypeStructOrUnion(`type`)
          of ""                : parser.readRequires(`type`)
          else: raise newException(ParsingError,"Can not identify category of type: " & category)
      else:
        let requires = `type`.attr("requires").removeExtraSpace()
        if parser.registry.externalTypes.containsOrIncl(`type`.attr("name").removeExtraSpace(),ExternalTypeData(require: requires, xmlLine: `type`.lineNumber)):
          duplicateAddError("externalTypes",`type`.attr("name"),`type`.lineNumber)
        if parser.registry.types.containsOrIncl(`type`.attr("name").removeExtraSpace(),TypeData(category: TypeCategory.ExternalType, requiredBy: toOrderedSet([requires]), xmlLine: `type`.lineNumber)):
          duplicateAddError("type",`type`.attr("name"),`type`.lineNumber)

