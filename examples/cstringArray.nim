#_______________________________________
# Also available from nstd
# Should copy/paste into VulkanNim/strings.nim to avoid the user depending on any specific library
# https://github.com/heysokam/nstd/blob/master/src/nstd/strings.nim#L100
#_______________________________________


#_______________________________________
# @section Automatic : CStringArray
#_____________________________
type CStringArray * = distinct cstringArray
proc `=wasMoved` *(arr :var CStringArray) :void;
proc `=copy` *(arr: var CStringArray; source: CStringArray) {.error.}
proc `=destroy` *(arr :CStringArray) :void= deallocCstringArray(arr.cstringArray)
proc `=wasMoved` *(arr: var CStringArray) :void= arr = nil.CStringArray
proc create *(_:typedesc[CStringArray]; list :openArray[string]) :CStringArray= allocCstringArray(list).CStringArray
converter toC *(list :openArray[string]) :cstringArray=
  if list.len == 0: return nil.cstringArray
  CStringArray.create(list).cstringArray


#_______________________________________
# @section Usage example
#_____________________________
# Notice how we can now use this!!
# extensions: openArray[string] = @[]
#___________________
proc create *(_:typedesc[VkInstance];
    appInfo    : VkApplicationInfo;
    layers     : openArray[string] = @[];
    extensions : openArray[string] = @[];
    allocator  : ptr VkAllocationCallbacks = nil;
  ) :VkInstance=
  ## @descr Creates a new Vulkan Instance
  let info = VkInstanceCreateInfo(
    flags                   : VkInstanceCreateFlags(0),
    pApplicationInfo        : appInfo.addr,
    enabledLayerCount       : layers.len.uint32,
    ppEnabledLayerNames     : layers.toC(),
    enabledExtensionCount   : extensions.len.uint32,
    ppEnabledExtensionNames : extensions.toC(),
  )
  let status = VkcreateInstance(info.addr, allocator, result.addr)
  if status != VkSuccess: raise newException(vk.InstanceError, "Failed to create Vulkan instance: {$status}")
#___________________
proc destroy *(
    instance :VkInstance;
    allocator :ptr VkAllocationCallbacks = nil
  ) :void= VkdestroyInstance(instance, allocator)

