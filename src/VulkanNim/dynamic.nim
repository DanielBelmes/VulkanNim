import dynlib

when defined(windows):
    const vkDLL = "vulkan-1.dll"
elif defined(macosx):
    when defined(libMoltenVK):
        const vkDLL = "libMoltenVK.dylib"
    else:
        const vkDLL = "libvulkan.1.dylib"
else:
    const vkDLL = "libvulkan.so.1"

let vkHandleDLL = loadLib(vkDLL)
if isNil(vkHandleDLL):
    quit("could not load: " & vkDLL)