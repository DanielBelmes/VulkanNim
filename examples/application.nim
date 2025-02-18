import std/options
import nglfw as glfw
import sets
import bitops
import VulkanNim
from errors import RuntimeException
import types
from utils import cStringToString

const
    validationLayers = ["VK_LAYER_KHRONOS_validation"]
    vkInstanceExtensions: array[0, string] = []
    deviceExtensions = [VK_KHR_SWAPCHAIN_EXTENSION_NAME]
    WIDTH* = 800
    HEIGHT* = 600
    MAX_FRAMES_IN_FLIGHT: uint32 = 2

when not defined(release):
    const enableValidationLayers = true
else:
    const enableValidationLayers = false

type
    VulkanTriangleApp* = ref object
        instance: VkInstance
        window: glfw.Window
        surface: VkSurfaceKHR
        physicalDevice: VkPhysicalDevice
        graphicsQueue: VkQueue
        presentQueue: VkQueue
        device: VkDevice
        swapChain: VkSwapchainKHR
        swapChainImages: seq[VkImage]
        swapChainImageFormat: VkFormat
        swapChainExtent: VkExtent2D
        swapChainImageViews: seq[VkImageView]
        pipelineLayout: VkPipelineLayout
        renderPass: VkRenderPass
        graphicsPipeline: VkPipeline
        swapChainFramebuffers: seq[VkFramebuffer]
        commandPool: VkCommandPool
        commandBuffers: seq[VkCommandBuffer]
        imageAvailableSemaphores: seq[VkSemaphore]
        renderFinishedSemaphores: seq[VkSemaphore]
        inFlightFences: seq[VkFence]
        currentFrame: uint32
        framebufferResized: bool

proc framebufferResizeCallback(window: glfw.Window, width: int32, height: int32) {.cdecl.} =
    let app = cast[ptr VulkanTriangleApp](glfw.getWindowUserPointer(window))
    app.framebufferResized = true

proc keyCallback (window :glfw.Window; key, code, action, mods :int32) :void {.cdecl.}=
  ## GLFW Keyboard Input Callback
  if (key == glfw.KeyEscape and action == glfw.Press):
    glfw.setWindowShouldClose(window, true)

proc initWindow(self: VulkanTriangleApp) =
    doAssert glfw.init()
    doAssert glfw.vulkanSupported()

    glfw.windowHint(glfw.ClientApi, glfw.NoApi)

    self.window = glfw.createWindow(WIDTH.cint, HEIGHT.cint, "Vulkan", nil, nil)
    doAssert self.window != nil
    glfw.setWindowUserPointer(self.window, unsafeAddr self);
    discard glfw.setKeyCallback(self.window, keyCallback)
    discard glfw.setFramebufferSizeCallback(self.window, framebufferResizeCallback)


proc checkValidationLayerSupport(): bool =
    var layerCount: uint32
    discard vkEnumerateInstanceLayerProperties(addr layerCount, nil)

    var availableLayers = newSeq[VkLayerProperties](layerCount)
    discard vkEnumerateInstanceLayerProperties(addr layerCount, addr availableLayers[0])

    for layerName in validationLayers:
        var layerFound: bool = false
        for layerProperties in availableLayers:
            if cmp(layerName, cStringToString(layerProperties.layerName)) == 0:
                layerFound = true
                break

        if not layerFound:
            return false

    return true

proc createInstance(self: VulkanTriangleApp) =
    var appInfo = VkApplicationInfo(
        pApplicationName: "NimGL Vulkan Example",
        applicationVersion: vkMakeVersion(1, 0, 0),
        pEngineName: "No Engine",
        engineVersion: vkMakeVersion(1, 0, 0),
        apiVersion: VK_API_VERSION_1_1
    )

    var glfwExtensionCount: uint32 = 0
    var glfwExtensions: cstringArray

    glfwExtensions = glfw.getRequiredInstanceExtensions(addr glfwExtensionCount)
    var extensions: seq[string]
    for ext in cstringArrayToSeq(glfwExtensions, glfwExtensionCount):
        extensions.add(ext)
    for ext in vkInstanceExtensions:
        extensions.add(ext)
    var allExtensions = allocCStringArray(extensions)


    var layerCount: uint32 = 0
    var enabledLayers: cstringArray = nil

    if enableValidationLayers:
        layerCount = uint32(validationLayers.len)
        enabledLayers = allocCStringArray(validationLayers)

    var createInfo = VkInstanceCreateInfo(
        pApplicationInfo: addr appInfo,
        enabledExtensionCount: glfwExtensionCount + uint32(vkInstanceExtensions.len),
        ppEnabledExtensionNames: allExtensions,
        enabledLayerCount: layerCount,
        ppEnabledLayerNames: enabledLayers,
    )

    if enableValidationLayers and not checkValidationLayerSupport():
        raise newException(RuntimeException, "validation layers requested, but not available!")

    if vkCreateInstance(addr createInfo, nil, addr self.instance) != Success:
        quit("failed to create instance")

    if enableValidationLayers and not enabledLayers.isNil:
        deallocCStringArray(enabledLayers)

    if not allExtensions.isNil:
        deallocCStringArray(allExtensions)

proc createSurface(self: VulkanTriangleApp) =
    if glfw.createWindowSurface(self.instance, self.window, nil, addr self.surface) != Success:
        raise newException(RuntimeException, "failed to create window surface")

proc checkDeviceExtensionSupport(self: VulkanTriangleApp, pDevice: VkPhysicalDevice): bool =
    var extensionCount: uint32
    discard vkEnumerateDeviceExtensionProperties(pDevice, nil, addr extensionCount, nil)
    var availableExtensions: seq[VkExtensionProperties] = newSeq[VkExtensionProperties](extensionCount)
    discard vkEnumerateDeviceExtensionProperties(pDevice, nil, addr extensionCount, addr availableExtensions[0])
    var requiredExtensions: HashSet[string] = deviceExtensions.toHashSet

    for extension in availableExtensions.mitems:
        requiredExtensions.excl(extension.extensionName.cStringToString)
    return requiredExtensions.len == 0

proc querySwapChainSupport(self: VulkanTriangleApp, pDevice: VkPhysicalDevice): SwapChainSupportDetails =
    discard vkGetPhysicalDeviceSurfaceCapabilitiesKHR(pDevice,self.surface,addr result.capabilities)
    var formatCount: uint32
    discard vkGetPhysicalDeviceSurfaceFormatsKHR(pDevice, self.surface, addr formatCount, nil)

    if formatCount != 0:
        result.formats.setLen(formatCount)
        discard vkGetPhysicalDeviceSurfaceFormatsKHR(pDevice, self.surface, formatCount.addr, result.formats[0].addr)
    var presentModeCount: uint32
    discard vkGetPhysicalDeviceSurfacePresentModesKHR(pDevice, self.surface, presentModeCount.addr, nil)
    if presentModeCount != 0:
        result.presentModes.setLen(presentModeCount)
        discard vkGetPhysicalDeviceSurfacePresentModesKHR(pDevice, self.surface, presentModeCount.addr, result.presentModes[0].addr)

proc chooseSwapSurfaceFormat(self: VulkanTriangleApp, availableFormats: seq[VkSurfaceFormatKHR]): VkSurfaceFormatKHR =
    for format in availableFormats:
        if format.format == FormatB8g8r8a8Srgb and format.colorSpace == ColorSpaceSrgbNonlinearKhr:
            return format
    return availableFormats[0]

proc chooseSwapPresnetMode(self: VulkanTriangleApp, availablePresentModes: seq[VkPresentModeKHR]): VkPresentModeKHR =
    for presentMode in availablePresentModes:
        if presentMode == PresentModeMailboxKhr:
            return presentMode
    return PresentModeFifoKhr

proc chooseSwapExtent(self: VulkanTriangleApp, capabilities: VkSurfaceCapabilitiesKHR): VkExtent2D =
    if capabilities.currentExtent.width != uint32.high:
        return capabilities.currentExtent
    else:
        var width: int32
        var height: int32
        getFramebufferSize(self.window, addr width, addr height)
        result.width = clamp(cast[uint32](width),
                                capabilities.minImageExtent.width,
                                capabilities.maxImageExtent.width)
        result.height = clamp(cast[uint32](height),
                                capabilities.minImageExtent.height,
                                capabilities.maxImageExtent.height)

proc findQueueFamilies(self: VulkanTriangleApp, pDevice: VkPhysicalDevice): QueueFamilyIndices =
    var queueFamilyCount: uint32 = 0
    vkGetPhysicalDeviceQueueFamilyProperties(pDevice, addr queueFamilyCount, nil)
    var queueFamilies: seq[VkQueueFamilyProperties] = newSeq[VkQueueFamilyProperties](queueFamilyCount) # [TODO] this pattern can be templated
    vkGetPhysicalDeviceQueueFamilyProperties(pDevice, addr queueFamilyCount, addr queueFamilies[0])
    var index: uint32 = 0
    for queueFamily in queueFamilies:
        if (queueFamily.queueFlags.uint32 and QueueGraphicsBit.uint32) > 0'u32:
            result.graphicsFamily = some(index)
        var presentSupport: VkBool32 = VkBool32(VK_FALSE)
        discard vkGetPhysicalDeviceSurfaceSupportKHR(pDevice, index, self.surface, addr presentSupport)
        if presentSupport.ord == 1:
            result.presentFamily = some(index)

        if(result.isComplete()):
            break
        index.inc

proc isDeviceSuitable(self: VulkanTriangleApp, pDevice: VkPhysicalDevice): bool =
    var deviceProperties: VkPhysicalDeviceProperties
    vkGetPhysicalDeviceProperties(pDevice, deviceProperties.addr)
    var indicies: QueueFamilyIndices = self.findQueueFamilies(pDevice)
    var extensionsSupported = self.checkDeviceExtensionSupport(pDevice)
    var swapChainAdequate = false
    if extensionsSupported:
        var swapChainSupport: SwapChainSupportDetails = self.querySwapChainSupport(pDevice)
        swapChainAdequate = swapChainSupport.formats.len != 0 and swapChainSupport.presentModes.len != 0
    return indicies.isComplete and extensionsSupported and swapChainAdequate

proc pickPhysicalDevice(self: VulkanTriangleApp) =
    var deviceCount: uint32 = 0
    discard vkEnumeratePhysicalDevices(self.instance, addr deviceCount, nil)
    if(deviceCount == 0):
        raise newException(RuntimeException, "failed to find GPUs with Vulkan support!")
    var pDevices: seq[VkPhysicalDevice] = newSeq[VkPhysicalDevice](deviceCount)
    discard vkEnumeratePhysicalDevices(self.instance, addr deviceCount, addr pDevices[0])
    for pDevice in pDevices:
        if self.isDeviceSuitable(pDevice):
            self.physicalDevice = pDevice
            return

    raise newException(RuntimeException, "failed to find a suitable GPU!")

proc createLogicalDevice(self: VulkanTriangleApp) =
    let
        indices = self.findQueueFamilies(self.physicalDevice)
        uniqueQueueFamilies = [indices.graphicsFamily.get, indices.presentFamily.get].toHashSet
    var
        queuePriority = 1f
        queueCreateInfos = newSeq[VkDeviceQueueCreateInfo]()

    for queueFamily in uniqueQueueFamilies:
        let deviceQueueCreateInfo: VkDeviceQueueCreateInfo = VkDeviceQueueCreateInfo(
            queueFamilyIndex: queueFamily,
            queueCount: 1,
            pQueuePriorities: queuePriority.addr
        )
        queueCreateInfos.add(deviceQueueCreateInfo)

    var
        deviceFeatures = newSeq[VkPhysicalDeviceFeatures](1)
        deviceExts = allocCStringArray(deviceExtensions)
        deviceCreateInfo = VkDeviceCreateInfo(
            pQueueCreateInfos: queueCreateInfos[0].addr,
            queueCreateInfoCount: queueCreateInfos.len.uint32,
            pEnabledFeatures: deviceFeatures[0].addr,
            enabledExtensionCount: deviceExtensions.len.uint32,
            enabledLayerCount: 0,
            ppEnabledLayerNames: nil,
            ppEnabledExtensionNames: deviceExts
        )

    if vkCreateDevice(self.physicalDevice, deviceCreateInfo.addr, nil, self.device.addr) != Success:
        echo "failed to create logical device"

    if not deviceExts.isNil:
        deallocCStringArray(deviceExts)

    vkGetDeviceQueue(self.device, indices.graphicsFamily.get, 0, addr self.graphicsQueue)
    vkGetDeviceQueue(self.device, indices.presentFamily.get, 0, addr self.presentQueue)


proc createSwapChain(self: VulkanTriangleApp) =
    let swapChainSupport: SwapChainSupportDetails = self.querySwapChainSupport(self.physicalDevice)

    let surfaceFormat: VkSurfaceFormatKHR = self.chooseSwapSurfaceFormat(swapChainSupport.formats)
    let presentMode: VkPresentModeKHR = self.chooseSwapPresnetMode(swapChainSupport.presentModes)
    let extent: VkExtent2D = self.chooseSwapExtent(swapChainSupport.capabilities)

    var imageCount: uint32 = swapChainSupport.capabilities.minImageCount + 1 # request one extra per recommended settings

    if swapChainSupport.capabilities.maxImageCount > 0 and imageCount > swapChainSupport.capabilities.maxImageCount:
        imageCount = swapChainSupport.capabilities.maxImageCount

    var createInfo = VkSwapchainCreateInfoKHR(
        sType: StructureTypeSwapchainCreateInfoKhr,
        surface: self.surface,
        minImageCount: imageCount,
        imageFormat: surfaceFormat.format,
        imageColorSpace: surfaceFormat.colorSpace,
        imageExtent: extent,
        imageArrayLayers: 1,
        imageUsage: VkImageUsageFlags(ImageUsageColorAttachmentBit),
        preTransform: swapChainSupport.capabilities.currentTransform,
        compositeAlpha: CompositeAlphaOpaqueBitKhr,
        presentMode: presentMode,
        clipped: VKBool32(VK_TRUE),
        oldSwapchain: VkSwapchainKHR(VK_NULL_HANDLE)
    )
    let indices = self.findQueueFamilies(self.physicalDevice)
    var queueFamilyIndicies = [indices.graphicsFamily.get, indices.presentFamily.get]

    if indices.graphicsFamily.get != indices.presentFamily.get:
        createInfo.imageSharingMode = SharingModeConcurrent
        createInfo.queueFamilyIndexCount = 2
        createInfo.pQueueFamilyIndices = queueFamilyIndicies[0].addr
    else:
        createInfo.imageSharingMode = SharingModeExclusive
        createInfo.queueFamilyIndexCount = 0
        createInfo.pQueueFamilyIndices = nil

    if vkCreateSwapchainKHR(self.device, addr createInfo, nil, addr self.swapChain) != Success:
        raise newException(RuntimeException, "failed to create swap chain!")
    discard vkGetSwapchainImagesKHR(self.device, self.swapChain, addr imageCount, nil)
    self.swapChainImages.setLen(imageCount)
    discard vkGetSwapchainImagesKHR(self.device, self.swapChain, addr imageCount, addr self.swapChainImages[0])
    self.swapChainImageFormat = surfaceFormat.format
    self.swapChainExtent = extent

proc createImageViews(self: VulkanTriangleApp) =
    self.swapChainImageViews.setLen(self.swapChainImages.len)
    for index, swapChainImage in self.swapChainImages:
        var createInfo = VkImageViewCreateInfo(
            image: swapChainImage,
            viewType: ImageViewType2d,
            format: self.swapChainImageFormat,
            components: VkComponentMapping(r:ComponentSwizzleIdentity,g:ComponentSwizzleIdentity,b:ComponentSwizzleIdentity,a:ComponentSwizzleIdentity),
            subresourceRange: VkImageSubresourceRange(aspectMask: VkImageAspectFlags(ImageAspectColorBit), baseMipLevel: 0.uint32, levelCount: 1.uint32, baseArrayLayer: 0.uint32, layerCount: 1.uint32)
        )
        echo createInfo.subresourceRange.aspectMask.uint32
        if vkCreateImageView(self.device, addr createInfo, nil, addr self.swapChainImageViews[index]) != Success:
            raise newException(RuntimeException, "failed to create image views")

proc createShaderModule(self: VulkanTriangleApp, code: string) : VkShaderModule =
    var createInfo = VkShaderModuleCreateInfo(
        codeSize: code.len.uint32,
        pCode: cast[ptr uint32](code[0].unsafeAddr) #Hopefully reading bytecode as string is alright
    )
    if vkCreateShaderModule(self.device, addr createInfo, nil, addr result) != Success:
        raise newException(RuntimeException, "failed to create shader module")

proc createRenderPass(self: VulkanTriangleApp) =
    var
        colorAttachment: VkAttachmentDescription = VkAttachmentDescription(
            format: self.swapChainImageFormat,
            samples: SampleCount1Bit,
            loadOp: AttachmentLoadOpClear,
            storeOp: AttachmentStoreOpStore,
            stencilLoadOp: AttachmentLoadOpDontCare,
            stencilStoreOp: AttachmentStoreOpDontCare,
            initialLayout: ImageLayoutUndefined,
            finalLayout: ImageLayoutPresentSrcKhr,
        )
        colorAttachmentRef: VkAttachmentReference = VkAttachmentReference(
            attachment: 0,
            layout: ImageLayoutColorAttachmentOptimal,
        )
        subpass = VkSubpassDescription(
            pipelineBindPoint: PipelineBindPointGraphics,
            colorAttachmentCount: 1,
            pColorAttachments: addr colorAttachmentRef,
        )
        dependency: VkSubpassDependency = VkSubpassDependency(
            srcSubpass: VK_SUBPASS_EXTERNAL,
            dstSubpass: 0,
            srcStageMask: VkPipelineStageFlags(PipelineStageColorAttachmentOutputBit),
            srcAccessMask: VkAccessFlags(0),
            dstStageMask: VkPipelineStageFlags(PipelineStageColorAttachmentOutputBit),
            dstAccessMask: VkAccessFlags(AccessColorAttachmentWriteBit),
        )
        renderPassInfo: VkRenderPassCreateInfo = VkRenderPassCreateInfo(
            attachmentCount: 1,
            pAttachments: addr colorAttachment,
            subpassCount: 1,
            pSubpasses: addr subpass,
            dependencyCount: 1,
            pDependencies: addr dependency,
        )
    if vkCreateRenderPass(self.device, addr renderPassInfo, nil, addr self.renderPass) != Success:
        quit("failed to create render pass")

proc createGraphicsPipeline(self: VulkanTriangleApp) =
    const
        vertShaderCode: string = staticRead("./shaders/vert.spv")
        fragShaderCode: string = staticRead("./shaders/frag.spv")
    var
        vertShaderModule: VkShaderModule = self.createShaderModule(vertShaderCode)
        fragShaderModule: VkShaderModule = self.createShaderModule(fragShaderCode)
        vertShaderStageInfo: VkPipelineShaderStageCreateInfo = VkPipelineShaderStageCreateInfo(
            stage: ShaderStageVertexBit,
            module: vertShaderModule,
            pName: "main",
            pSpecializationInfo: nil
        )
        fragShaderStageInfo: VkPipelineShaderStageCreateInfo = VkPipelineShaderStageCreateInfo(
            stage: ShaderStageFragmentBit,
            module: fragShaderModule,
            pName: "main",
            pSpecializationInfo: nil
        )
        shaderStages: array[2, VkPipelineShaderStageCreateInfo] = [vertShaderStageInfo, fragShaderStageInfo]
        dynamicStates: array[2, VkDynamicState] = [DynamicStateViewport, DynamicStateScissor]
        dynamicState: VkPipelineDynamicStateCreateInfo = VkPipelineDynamicStateCreateInfo(
            dynamicStateCount: dynamicStates.len.uint32,
            pDynamicStates: addr dynamicStates[0]
        )
        vertexInputInfo: VkPipelineVertexInputStateCreateInfo = VkPipelineVertexInputStateCreateInfo(
            vertexBindingDescriptionCount: 0,
            pVertexBindingDescriptions: nil,
            vertexAttributeDescriptionCount: 0,
            pVertexAttributeDescriptions: nil
        )
        inputAssembly: VkPipelineInputAssemblyStateCreateInfo = VkPipelineInputAssemblyStateCreateInfo(
            topology: PrimitiveTopologyTriangleList,
            primitiveRestartEnable: VkBool32(VK_FALSE)
        )
        viewport: VkViewPort = VkViewport(
            x : 0.float,
            y : 0.float,
            width : self.swapChainExtent.width.float32,
            height : self.swapChainExtent.height.float32,
            minDepth : 0.float,
            maxDepth : 1.float
        )
        scissor: VkRect2D = VkRect2D(
            offset : VkOffset2D(x: 0,y: 0),
            extent : self.swapChainExtent
        )
        viewportState: VkPipelineViewportStateCreateInfo = VkPipelineViewportStateCreateInfo(
            viewportCount : 1,
            pViewports : addr viewport,
            scissorCount : 1,
            pScissors : addr scissor
        )
        rasterizer: VkPipelineRasterizationStateCreateInfo = VkPipelineRasterizationStateCreateInfo(
            depthClampEnable : VkBool32(VK_FALSE),
            rasterizerDiscardEnable : VkBool32(VK_FALSE),
            polygonMode : PolygonModeFill,
            lineWidth : 1.float,
            cullMode : VkCullModeFlags(CullModeBackBit),
            frontface : FrontFaceClockwise,
            depthBiasEnable : VKBool32(VK_FALSE),
            depthBiasConstantFactor : 0.float,
            depthBiasClamp : 0.float,
            depthBiasSlopeFactor : 0.float,
        )
        multisampling: VkPipelineMultisampleStateCreateInfo = VkPipelineMultisampleStateCreateInfo(
            sampleShadingEnable : VkBool32(VK_FALSE),
            rasterizationSamples : SampleCount1Bit,
            minSampleShading : 1.float,
            pSampleMask : nil,
            alphaToCoverageEnable : VkBool32(VK_FALSE),
            alphaToOneEnable : VkBool32(VK_FALSE)
        )
        # [NOTE] Not doing VkPipelineDepthStencilStateCreateInfo because we don't have a depth or stencil buffer yet
        colorBlendAttachment: VkPipelineColorBlendAttachmentState = VkPipelineColorBlendAttachmentState(
            colorWriteMask : VkColorComponentFlags(bitor(ColorComponentRBit.int32, bitor(ColorComponentGBit.int32, bitor(ColorComponentBBit.int32, ColorComponentABit.int32)))),
            blendEnable : VkBool32(VK_FALSE),
            srcColorBlendFactor : BlendFactorOne, # optional
            dstColorBlendFactor : BlendFactorZero, # optional
            colorBlendOp : BlendOpAdd, # optional
            srcAlphaBlendFactor : BlendFactorOne, # optional
            dstAlphaBlendFactor : BlendFactorZero, # optional
            alphaBlendOp : BlendOpAdd, # optional
        )
        colorBlending: VkPipelineColorBlendStateCreateInfo = VkPipelineColorBlendStateCreateInfo(
            logicOpEnable : VkBool32(VK_FALSE),
            logicOp : LogicOpCopy, # optional
            attachmentCount : 1,
            pAttachments : colorBlendAttachment.addr,
            blendConstants : [0f, 0f, 0f, 0f], # optional
        )
        pipelineLayoutInfo: VkPipelineLayoutCreateInfo = VkPipelineLayoutCreateInfo(
            setLayoutCount : 0, # optional
            pSetLayouts : nil, # optional
            pushConstantRangeCount : 0, # optional
            pPushConstantRanges : nil, # optional
        )
    if vkCreatePipelineLayout(self.device, pipelineLayoutInfo.addr, nil, addr self.pipelineLayout) != Success:
        quit("failed to create pipeline layout")
    var
        pipelineInfo: VkGraphicsPipelineCreateInfo = VkGraphicsPipelineCreateInfo(
            stageCount : shaderStages.len.uint32,
            pStages : shaderStages[0].addr,
            pVertexInputState : vertexInputInfo.addr,
            pInputAssemblyState : inputAssembly.addr,
            pViewportState : viewportState.addr,
            pRasterizationState : rasterizer.addr,
            pMultisampleState : multisampling.addr,
            pDepthStencilState : nil, # optional
            pColorBlendState : colorBlending.addr,
            pDynamicState : dynamicState.addr, # optional
            pTessellationState : nil,
            layout : self.pipelineLayout,
            renderPass : self.renderPass,
            subpass : 0,
            basePipelineHandle : VkPipeline(0), # optional
            basePipelineIndex : -1, # optional
        )
    if vkCreateGraphicsPipelines(self.device, VkPipelineCache(0), 1, pipelineInfo.addr, nil, addr self.graphicsPipeline) != Success:
        quit("fialed to create graphics pipeline")
    vkDestroyShaderModule(self.device, vertShaderModule, nil)
    vkDestroyShaderModule(self.device, fragShaderModule, nil)

proc createFrameBuffers(self: VulkanTriangleApp) =
    self.swapChainFramebuffers.setLen(self.swapChainImageViews.len)

    for index, view in self.swapChainImageViews:
        var
            attachments = [self.swapChainImageViews[index]]
            framebufferInfo = VkFramebufferCreateInfo(
                sType : StructureTypeFrameBufferCreateInfo,
                renderPass : self.renderPass,
                attachmentCount : attachments.len.uint32,
                pAttachments : attachments[0].addr,
                width : self.swapChainExtent.width,
                height : self.swapChainExtent.height,
                layers : 1,
            )
        if vkCreateFramebuffer(self.device, framebufferInfo.addr, nil, addr self.swapChainFramebuffers[index]) != Success:
            quit("failed to create framebuffer")

proc cleanupSwapChain(self: VulkanTriangleApp) =
    for framebuffer in self.swapChainFramebuffers:
        vkDestroyFramebuffer(self.device, framebuffer, nil)
    for imageView in self.swapChainImageViews:
        vkDestroyImageView(self.device, imageView, nil)
    vkDestroySwapchainKHR(self.device, self.swapChain, nil)

proc recreateSwapChain(self: VulkanTriangleApp) =
    var
        width: int32 = 0
        height: int32 = 0
    getFramebufferSize(self.window, addr width, addr height)
    while width == 0 or height == 0:
        getFramebufferSize(self.window, addr width, addr height)
        glfw.waitEvents()
    discard vkDeviceWaitIdle(self.device)

    self.cleanupSwapChain()

    self.createSwapChain()
    self.createImageViews()
    self.createFramebuffers()

proc createCommandPool(self: VulkanTriangleApp) =
    var
        indicies: QueueFamilyIndices = self.findQueueFamilies(self.physicalDevice) # I should just save this info. Does it change?
        poolInfo: VkCommandPoolCreateInfo = VkCommandPoolCreateInfo(
            flags : VkCommandPoolCreateFlags(CommandPoolCreateResetCommandBufferBit),
            queueFamilyIndex: indicies.graphicsFamily.get
        )
    if vkCreateCommandPool(self.device, addr poolInfo, nil, addr self.commandPool) != Success:
        raise newException(RuntimeException, "failed to create command pool!")

proc createCommandBuffers(self: VulkanTriangleApp) =
    self.commandBuffers.setLen(MAX_FRAMES_IN_FLIGHT)
    var allocInfo: VkCommandBufferAllocateInfo = VkCommandBufferAllocateInfo(
        commandPool : self.commandPool,
        level : CommandBufferLevelPrimary,
        commandBufferCount: cast[uint32](self.commandBuffers.len)
    )
    if vkAllocateCommandBuffers(self.device, addr allocInfo, addr self.commandBuffers[0]) != Success:
        raise newException(RuntimeException, "failed to allocate command buffers!")

proc recordCommandBuffer(self: VulkanTriangleApp, commandBuffer: VkCommandBuffer, imageIndex: uint32) =
    var beginInfo: VkCommandBufferBeginInfo = VkCommandBufferBeginInfo()
    if vkBeginCommandBuffer(commandBuffer, addr beginInfo) != Success:
        raise newException(RuntimeException, "failed to begin recording command buffer!")

    var
        clearColor: VkClearValue = VkClearValue(color: VkClearColorValue(float32: [0f, 0f, 0f, 1f]))
        renderPassInfo: VkRenderPassBeginInfo = VkRenderPassBeginInfo(
            renderPass : self.renderPass,
            framebuffer : self.swapChainFrameBuffers[imageIndex],
            renderArea: VkRect2D(
                offset: VkOffset2d(x: 0,y: 0),
                extent: self.swapChainExtent
            ),
            clearValueCount : 1,
            pClearValues: addr clearColor
        )
    vkCmdBeginRenderPass(commandBuffer, renderPassInfo.addr, SubpassContentsInline)
    var
        viewport: VkViewport = VkViewport(
            x : 0f,
            y : 0f,
            width : self.swapChainExtent.width.float32,
            height : self.swapChainExtent.height.float32,
            minDepth : 0f,
            maxDepth: 1f
        )
        scissor: VkRect2D = VkRect2D(
            offset: VkOffset2D(x: 0, y: 0),
            extent: self.swapChainExtent
        )
    vkCmdSetViewport(commandBuffer, 0, 1, addr viewport)
    vkCmdSetScissor(commandBuffer, 0, 1, addr scissor)
    vkCmdBindPipeline(commandBuffer, PipelineBindPointGraphics, self.graphicsPipeline)
    vkCmdDraw(commandBuffer, 3, 1, 0, 0)
    vkCmdEndRenderPass(commandBuffer)
    if vkEndCommandBuffer(commandBuffer) != Success:
        quit("failed to record command buffer")

proc createSyncObjects(self: VulkanTriangleApp) =
    self.imageAvailableSemaphores.setLen(MAX_FRAMES_IN_FLIGHT)
    self.renderFinishedSemaphores.setLen(MAX_FRAMES_IN_FLIGHT)
    self.inFlightFences.setLen(MAX_FRAMES_IN_FLIGHT)
    var
        semaphoreInfo: VkSemaphoreCreateInfo = VkSemaphoreCreateInfo()
        fenceInfo: VkFenceCreateInfo = VkFenceCreateInfo(
            flags: VkFenceCreateFlags(FenceCreateSignaledBit)
        )
    for i in countup(0,cast[int](MAX_FRAMES_IN_FLIGHT-1)):
        if  (vkCreateSemaphore(self.device, addr semaphoreInfo, nil, addr self.imageAvailableSemaphores[i]) != Success) or 
            (vkCreateSemaphore(self.device, addr semaphoreInfo, nil, addr self.renderFinishedSemaphores[i]) != Success) or 
            (vkCreateFence(self.device, addr fenceInfo, nil, addr self.inFlightFences[i]) != Success):
                raise newException(RuntimeException, "failed to create sync Objects!")

proc drawFrame(self: VulkanTriangleApp) =
    discard vkWaitForFences(self.device, 1, addr self.inFlightFences[self.currentFrame], VkBool32(VK_TRUE), uint64.high)
    var imageIndex: uint32
    let imageResult: VkResult = vkAcquireNextImageKHR(self.device, self.swapChain, uint64.high, self.imageAvailableSemaphores[self.currentFrame], VkFence(0), addr imageIndex)
    if imageResult == ErrorOutOfDateKhr:
        self.recreateSwapChain();
        return
    elif (imageResult != Success and imageResult != SuboptimalKhr):
        raise newException(RuntimeException, "failed to acquire swap chain image!")

    # Only reset the fence if we are submitting work
    discard vkResetFences(self.device, 1 , addr self.inFlightFences[self.currentFrame])

    discard vkResetCommandBuffer(self.commandBuffers[self.currentFrame], VkCommandBufferResetFlags(0))
    self.recordCommandBuffer(self.commandBuffers[self.currentFrame], imageIndex)
    var
        waitSemaphores: array[1, VkSemaphore] = [self.imageAvailableSemaphores[self.currentFrame]]
        waitStages: array[1, VkPipelineStageFlags] = [VkPipelineStageFlags(PipelineStageColorAttachmentOutputBit)]
        signalSemaphores: array[1, VkSemaphore] = [self.renderFinishedSemaphores[self.currentFrame]]
        submitInfo: VkSubmitInfo = VkSubmitInfo(
            waitSemaphoreCount: waitSemaphores.len.uint32,
            pWaitSemaphores: addr waitSemaphores[0],
            pWaitDstStageMask: addr waitStages[0],
            commandBufferCount: 1,
            pCommandBuffers: addr self.commandBuffers[self.currentFrame],
            signalSemaphoreCount: 1,
            pSignalSemaphores: addr signalSemaphores[0]
        )
    if vkQueueSubmit(self.graphicsQueue, 1, addr submitInfo, self.inFlightFences[self.currentFrame]) != Success:
        raise newException(RuntimeException, "failed to submit draw command buffer")
    var
        swapChains: array[1, VkSwapchainKHR] = [self.swapChain]
        presentInfo: VkPresentInfoKHR = VkPresentInfoKHR(
            waitSemaphoreCount: 1,
            pWaitSemaphores: addr signalSemaphores[0],
            swapchainCount: 1,
            pSwapchains: addr swapChains[0],
            pImageIndices: addr imageIndex,
            pResults: nil
        )
    let queueResult = vkQueuePresentKHR(self.presentQueue, addr presentInfo)
    if queueResult == ErrorOutOfDateKhr or queueResult == SuboptimalKhr or self.framebufferResized:
        self.framebufferResized = false
        self.recreateSwapChain();
    elif queueResult != Success:
        raise newException(RuntimeException, "failed to present swap chain image!")
    self.currentFrame = (self.currentFrame + 1).mod(MAX_FRAMES_IN_FLIGHT)


proc initVulkan(self: VulkanTriangleApp) =
    self.createInstance()
    self.createSurface()
    self.pickPhysicalDevice()
    self.createLogicalDevice()
    self.createSwapChain()
    self.createImageViews()
    self.createRenderPass()
    self.createGraphicsPipeline()
    self.createFrameBuffers()
    self.createCommandPool()
    self.createCommandBuffers()
    self.createSyncObjects()
    self.framebufferResized = false
    self.currentFrame = 0

proc mainLoop(self: VulkanTriangleApp) =
    while not windowShouldClose(self.window):
        glfw.pollEvents()
        self.drawFrame()
    discard vkDeviceWaitIdle(self.device);

proc cleanup(self: VulkanTriangleApp) =
    for i in countup(0,cast[int](MAX_FRAMES_IN_FLIGHT-1)):
        vkDestroySemaphore(self.device, self.imageAvailableSemaphores[i], nil)
        vkDestroySemaphore(self.device, self.renderFinishedSemaphores[i], nil)
        vkDestroyFence(self.device, self.inFlightFences[i], nil)
    vkDestroyCommandPool(self.device, self.commandPool, nil)
    vkDestroyPipeline(self.device, self.graphicsPipeline, nil)
    vkDestroyPipelineLayout(self.device, self.pipelineLayout, nil)
    vkDestroyRenderPass(self.device, self.renderPass, nil)
    self.cleanupSwapChain()
    vkDestroyDevice(self.device, nil) #destroy device before instance
    vkDestroySurfaceKHR(self.instance, self.surface, nil)
    vkDestroyInstance(self.instance, nil)
    self.window.destroyWindow()
    glfw.terminate()

proc run*(self: VulkanTriangleApp) =
    self.initWindow()
    self.initVulkan()
    self.mainLoop()
    self.cleanup()