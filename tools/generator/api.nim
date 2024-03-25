# std dependencies
import std/strformat
# Generator dependencies
import ./base


proc generateAPI *(gen: Generator): void =
  let outputDir = fmt"./src/VulkanNim/{gen.api}.nim"
  const genTemplate = """
include ./dynamic
import {gen.api}_enum;export {gen.api}_enum
"""
  writeFile(outputDir,fmt genTemplate)

