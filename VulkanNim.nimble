# Package

version       = "0.1.0"
author        = "DanielBelmes"
description   = "Vulkan Nim bindings taking influence from VulkanHpp"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.1.1"

task gen, "Generate bindings from source":
  exec("nim c -r tools/generator.nim")