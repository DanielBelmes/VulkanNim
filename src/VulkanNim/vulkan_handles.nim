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
type VkDescriptorUpdateTemplate* = distinct VkNonDispatchableHandle
type VkSamplerYcbcrConversion* = distinct VkNonDispatchableHandle
type VkPrivateDataSlot* = distinct VkNonDispatchableHandle

