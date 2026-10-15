# converter dependencies
import nonim/codegen/nim as codegen


#_______________________________________
# @section Entry Point
#_____________________________
proc generate *(atf :string) :string=
  ## Converts the given astTF.json string into unchanged.nim code
  let ast  = atf.fromJson()
  let code = ast.nim(mode = BlockMode.none)
  result   = code.modules[ast.root].definitions

