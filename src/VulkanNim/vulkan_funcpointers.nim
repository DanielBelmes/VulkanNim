#[
=====================================

Types

=====================================
]#

#Function Pointers
type PFN_vkInternalAllocationNotification* = proc(pUserData: pointer; size: csize_t; allocationType: VkInternalAllocationType; allocationScope: VkSystemAllocationScope): void {.cdecl.}
type PFN_vkInternalFreeNotification* = proc(pUserData: pointer; size: csize_t; allocationType: VkInternalAllocationType; allocationScope: VkSystemAllocationScope): void {.cdecl.}
type PFN_vkReallocationFunction* = proc(pUserData: pointer; pOriginal: pointer; size: csize_t; alignment: csize_t; allocationScope: VkSystemAllocationScope): pointer {.cdecl.}
type PFN_vkAllocationFunction* = proc(pUserData: pointer; size: csize_t; alignment: csize_t; allocationScope: VkSystemAllocationScope): pointer {.cdecl.}
type PFN_vkFreeFunction* = proc(pUserData: pointer; pMemory: pointer): void {.cdecl.}
type PFN_vkVoidFunction* = proc(): void {.cdecl.}

