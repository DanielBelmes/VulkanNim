#[
=====================================

Handles

=====================================
]#

type
  VkHandle* = int64
  VkNonDispatchableHandle* = int64

type VkInstance* = distinct VkHandle
type VkPhysicalDevice* = distinct VkHandle
type VkDevice* = distinct VkHandle
type VkQueue* = distinct VkHandle
type VkCommandBuffer* = distinct VkHandle
type VkDeviceMemory* = distinct VkNonDispatchableHandle
type VkCommandPool* = distinct VkNonDispatchableHandle
type VkBuffer* = distinct VkNonDispatchableHandle
type VkBufferView* = distinct VkNonDispatchableHandle
type VkImage* = distinct VkNonDispatchableHandle
type VkImageView* = distinct VkNonDispatchableHandle
type VkShaderModule* = distinct VkNonDispatchableHandle
type VkPipeline* = distinct VkNonDispatchableHandle
type VkPipelineLayout* = distinct VkNonDispatchableHandle
type VkSampler* = distinct VkNonDispatchableHandle
type VkDescriptorSet* = distinct VkNonDispatchableHandle
type VkDescriptorSetLayout* = distinct VkNonDispatchableHandle
type VkDescriptorPool* = distinct VkNonDispatchableHandle
type VkFence* = distinct VkNonDispatchableHandle
type VkSemaphore* = distinct VkNonDispatchableHandle
type VkEvent* = distinct VkNonDispatchableHandle
type VkQueryPool* = distinct VkNonDispatchableHandle
type VkFramebuffer* = distinct VkNonDispatchableHandle
type VkRenderPass* = distinct VkNonDispatchableHandle
type VkPipelineCache* = distinct VkNonDispatchableHandle
type VkIndirectCommandsLayoutNV* = distinct VkNonDispatchableHandle
type VkDescriptorUpdateTemplate* = distinct VkNonDispatchableHandle
type VkSamplerYcbcrConversion* = distinct VkNonDispatchableHandle
type VkValidationCacheEXT* = distinct VkNonDispatchableHandle
type VkAccelerationStructureKHR* = distinct VkNonDispatchableHandle
type VkAccelerationStructureNV* = distinct VkNonDispatchableHandle
type VkPerformanceConfigurationINTEL* = distinct VkNonDispatchableHandle
type VkBufferCollectionFUCHSIA* = distinct VkNonDispatchableHandle
type VkDeferredOperationKHR* = distinct VkNonDispatchableHandle
type VkPrivateDataSlot* = distinct VkNonDispatchableHandle
type VkCuModuleNVX* = distinct VkNonDispatchableHandle
type VkCuFunctionNVX* = distinct VkNonDispatchableHandle
type VkOpticalFlowSessionNV* = distinct VkNonDispatchableHandle
type VkMicromapEXT* = distinct VkNonDispatchableHandle
type VkShaderEXT* = distinct VkNonDispatchableHandle
type VkDisplayKHR* = distinct VkNonDispatchableHandle
type VkDisplayModeKHR* = distinct VkNonDispatchableHandle
type VkSurfaceKHR* = distinct VkNonDispatchableHandle
type VkSwapchainKHR* = distinct VkNonDispatchableHandle
type VkDebugReportCallbackEXT* = distinct VkNonDispatchableHandle
type VkDebugUtilsMessengerEXT* = distinct VkNonDispatchableHandle
type VkVideoSessionKHR* = distinct VkNonDispatchableHandle
type VkVideoSessionParametersKHR* = distinct VkNonDispatchableHandle
type VkSemaphoreSciSyncPoolNV* = distinct VkNonDispatchableHandle
type VkCudaModuleNV* = distinct VkNonDispatchableHandle
type VkCudaFunctionNV* = distinct VkNonDispatchableHandle

