# std dependencies
import std/strformat
# Generator dependencies
import ./base


proc generateAPI *(gen: Generator): void =
  let outputDir = fmt"./src/VulkanNim/{gen.api}.nim"
  const genTemplate = """
{{.experimental: "codeReordering".}}
include ./dynamic
include {gen.api}_consts
include {gen.api}_types
include {gen.api}_funcpointers
include {gen.api}_enums
include {gen.api}_structs
include {gen.api}_procs
include {gen.api}_handles
"""
  writeFile(outputDir,fmt genTemplate)

