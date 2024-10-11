#[
=====================================

Types

=====================================
]#
import vulkan_enums
import vulkan_types
import vulkan_handles

#Function Pointers
type PFN_vkInternalAllocationNotification* = proc(pUserData: pointer; size: csize_t; allocationType: VkInternalAllocationType; allocationScope: VkSystemAllocationScope) {.cdecl.}
type PFN_vkInternalFreeNotification* = proc(pUserData: pointer; size: csize_t; allocationType: VkInternalAllocationType; allocationScope: VkSystemAllocationScope) {.cdecl.}
type PFN_vkReallocationFunction* = proc(pUserData: pointer; pOriginal: pointer; size: csize_t; alignment: csize_t; allocationScope: VkSystemAllocationScope): pointer {.cdecl.}
type PFN_vkAllocationFunction* = proc(pUserData: pointer; size: csize_t; alignment: csize_t; allocationScope: VkSystemAllocationScope): pointer {.cdecl.}
type PFN_vkFreeFunction* = proc(pUserData: pointer; pMemory: pointer) {.cdecl.}
type PFN_vkVoidFunction* = proc() {.cdecl.}
type PFN_vkFaultCallbackFunction* = proc(unrecordedFaults: VkBool32, faultCount: uint32, pFaults: pointer) {.cdecl.}
type PFN_vkGetInstanceProcAddrLUNARG* = proc(instance: VkInstance, pName: cstring) {.cdecl.}

