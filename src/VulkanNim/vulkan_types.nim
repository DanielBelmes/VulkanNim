#[
=====================================

Types

=====================================
]#

template vkMakeVersion*(major, minor, patch: untyped): untyped =
  (((major) shl 22) or ((minor) shl 12) or (patch))
template vkVersionMajor*(version: untyped): untyped =
  ((uint32)(version) shr 22)
template vkVersionMajor*(version: untyped): untyped =
  ((uint32)(version) shr 22)
template vkVersionPatch*(version: untyped): untyped =
  ((uint32)(version) and 0x00000FFF)
template vkMakeApiVersion*(variant, major, minor, patch: untyped): untyped =
  (((variant) shl 29) or ((major) shl 22) or ((minor) shl 12) or (patch))
template vkApiVersionVariant*(version: untyped): untyped =
  ((uint32)(version) shr 29)
template vkApiVersionMajor*(version: untyped): untyped =
  (((uint32)(version) shr 22) and 0x000007FU)
template vkApiVersionMinor*(version: untyped): untyped =
  (((uint32)(version) shr 12) and 0x000003FF)
template vkApiVersionPatch*(version: untyped): untyped =
  ((uint32)(version) and 0x00000FFF)
const VKSC_API_VARIANT* = 1
const VK_API_VERSION* = vkMakeApiVersion(0, 1, 0, 0)
const VK_API_VERSION_1_0* = vkMakeApiVersion(0, 1, 0, 0)
const VK_API_VERSION_1_1* = vkMakeApiVersion(0, 1, 1, 0)
const VK_API_VERSION_1_2* = vkMakeApiVersion(0, 1, 2, 0)
const VK_API_VERSION_1_3* = vkMakeApiVersion(0, 1, 3, 0)
const VKSC_API_VERSION_1_0* = vkMakeApiVersion(VKSC_API_VARIANT, 1, 0, 0)
const VK_HEADER_VERSION* = 281
const VK_HEADER_VERSION_COMPLETE* = vkMakeApiVersion(0, 1, 3, VK_HEADER_VERSION)
const VK_NULL_HANDLE* = 0

