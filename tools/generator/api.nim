# std dependencies
import std/strformat
# Generator dependencies
import ./base


proc generateAPI *(gen: Generator): void =
  let outputDir = fmt"./src/VulkanNim/{gen.api}.nim"
  const genTemplate = """
include ./dynamic
import {gen.api}_enums;export {gen.api}_enums
"""
  writeFile(outputDir,fmt genTemplate)

