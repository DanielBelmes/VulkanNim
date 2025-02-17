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
type PFN_vkDebugReportCallbackEXT* = proc(flags: VkDebugReportFlagsEXT; objectType: VkDebugReportObjectTypeEXT; `object`: uint64; location: csize_t; messageCode: int32; pLayerPrefix: cstring; pMessage: cstring; pUserData: pointer): VkBool32 {.cdecl.}
type PFN_vkDebugUtilsMessengerCallbackEXT* = proc(messageSeverity: VkDebugUtilsMessageSeverityFlagBitsEXT; messageTypes: VkDebugUtilsMessageTypeFlagsEXT; pCallbackData: VkDebugUtilsMessengerCallbackDataEXT; pUserData: pointer): VkBool32 {.cdecl.}
type PFN_vkDeviceMemoryReportCallbackEXT* = proc(pCallbackData: VkDeviceMemoryReportCallbackDataEXT; pUserData: pointer): void {.cdecl.}
type PFN_vkGetInstanceProcAddrLUNARG* = proc(instance: VkInstance; pName: cstring): PFN_vkVoidFunction {.cdecl.}

