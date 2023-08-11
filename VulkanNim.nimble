import std/os
import std/strformat

# Package
packageName   = "VulkanNim"
version       = "0.0.0"
author        = "DanielBelmes"
description   = "Vulkan Bindings for Nim | Influenced by VulkanHpp"
license       = "MIT"

# Build Requirements
requires "nim >= 2.0.0"

# Folders
srcDir          = "src"
binDir          = "bin"
let testsDir    = "tests"
let examplesDir = "examples"

# Generator config
let specDir   = "spec"
let specXML   = specDir/"xml"/"vk.xml"
let toolsDir  = "tools"
let generator = toolsDir/"generator.nim"

#________________________________________
# Helpers
#___________________
const vlevel = when defined(debug): 2 else: 1
let nimcr  = &"nim c -r --verbosity:{vlevel} --outdir:{binDir}"
  ## Compile and run, outputting to binDir
proc run (file, dir :string) :void=  exec &"{nimcr} {dir/file}"
  ## Runs file from the given dir, using the nimcr command
proc runTest (file :string) :void=  file.run(testsDir)
  ## Runs the given test file. Assumes the file is stored in the default testsDir folder
proc runExample (file :string) :void=  file.run(examplesDir)
  ## Runs the given test file. Assumes the file is stored in the default testsDir folder
template example (name :untyped; descr,file :static string)=
  ## Generates a task to build+run the given example
  let sname = astToStr(name)  # string name of the untyped task name
  # Examples dependencies
  taskRequires sname, "https://github.com/heysokam/nglfw" ## For window creation. GLFW bindings, without dynamic libraries required
  taskRequires sname, "vmath"                             ## Vector math library.
  # Example task
  task name, descr:
    runExample file

#________________________________________
# Tasks
#___________________
task git, "Internal:  Updates the Vulkan spec submodule.":
  withDir specDir:
    exec "git pull --recurse-submodules origin master"
#___________________
taskRequires "gen", "https://github.com/heysokam/nstd" # For parseopts extensions
task gen, "Internal:  Generates the bindings, using the currently tracked vk.xml file.":
  exec "nimble git"
  exec &"{nimcr} {generator} {specXML}"
#___________________
# Build the examples binaries
example wip, "Example WIP: Builds the current wip example.", "wip"

