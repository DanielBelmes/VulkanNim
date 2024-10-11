# std dependencies
import std/strformat
# Generator dependencies
import ./base


proc generateAPI *(gen: Generator): void =
  let outputDir = fmt"./src/VulkanNim/{gen.api}.nim"
  const genTemplate = """
include ./dynamic
import {gen.api}_enums;export {gen.api}_enums
import {gen.api}_structs;export {gen.api}_structs
import {gen.api}_procs;export {gen.api}_procs
import {gen.api}_consts;export {gen.api}_consts
import {gen.api}_types;export {gen.api}_types
import {gen.api}_funcpointers;export {gen.api}_funcpointers
import {gen.api}_handles;export {gen.api}_handles
"""
  writeFile(outputDir,fmt genTemplate)

