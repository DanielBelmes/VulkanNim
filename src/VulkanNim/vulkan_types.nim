#[
=====================================

Types

=====================================
]#

# defines
template vkMakeVersion*(major, minor, patch: untyped): untyped =
  (((major) shl 22) or ((minor) shl 12) or (patch))
template vkVersionMajor*(version: untyped): untyped =
  ((uint32)(version) shr 22)
template vkVersionMinor*(version: untyped): untyped =
  (((uint32)(version) shr 12) and 0x000003FF)
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
const VK_API_VERSION* = vkMakeApiVersion(0, 1, 0, 0)
const VK_API_VERSION_1_0* = vkMakeApiVersion(0, 1, 0, 0)
const VK_API_VERSION_1_1* = vkMakeApiVersion(0, 1, 1, 0)
const VK_API_VERSION_1_2* = vkMakeApiVersion(0, 1, 2, 0)
const VK_API_VERSION_1_3* = vkMakeApiVersion(0, 1, 3, 0)
const VK_HEADER_VERSION* = 281
const VK_HEADER_VERSION_COMPLETE* = vkMakeApiVersion(0, 1, 3, VK_HEADER_VERSION)
const VK_NULL_HANDLE* = 0


# Base types
type ANativeWindow* = ptr object
type AHardwareBuffer* = ptr object
type CAMetalLayer* = ptr object
type MTLDevice_id* = ptr object
type MTLCommandQueue_id* = ptr object
type MTLBuffer_id* = ptr object
type MTLTexture_id* = ptr object
type MTLSharedEvent_id* = ptr object
type IOSurfaceRef* = ptr object
type VkSampleMask* = distinct uint32
type VkBool32* = distinct uint32
type VkFlags* = distinct uint32
type VkFlags64* = distinct uint64
type VkDeviceSize* = distinct uint64
type VkDeviceAddress* = distinct uint64
type VkRemoteAddressNV* = distinct void


# Bitmasks
type VkFramebufferCreateFlags* = distinct VkFlags
type VkQueryPoolCreateFlags* = distinct VkFlags
type VkRenderPassCreateFlags* = distinct VkFlags
type VkSamplerCreateFlags* = distinct VkFlags
type VkPipelineLayoutCreateFlags* = distinct VkFlags
type VkPipelineCacheCreateFlags* = distinct VkFlags
type VkPipelineDepthStencilStateCreateFlags* = distinct VkFlags
type VkPipelineDynamicStateCreateFlags* = distinct VkFlags
type VkPipelineColorBlendStateCreateFlags* = distinct VkFlags
type VkPipelineMultisampleStateCreateFlags* = distinct VkFlags
type VkPipelineRasterizationStateCreateFlags* = distinct VkFlags
type VkPipelineViewportStateCreateFlags* = distinct VkFlags
type VkPipelineTessellationStateCreateFlags* = distinct VkFlags
type VkPipelineInputAssemblyStateCreateFlags* = distinct VkFlags
type VkPipelineVertexInputStateCreateFlags* = distinct VkFlags
type VkPipelineShaderStageCreateFlags* = distinct VkFlags
type VkDescriptorSetLayoutCreateFlags* = distinct VkFlags
type VkBufferViewCreateFlags* = distinct VkFlags
type VkInstanceCreateFlags* = distinct VkFlags
type VkDeviceCreateFlags* = distinct VkFlags
type VkDeviceQueueCreateFlags* = distinct VkFlags
type VkQueueFlags* = distinct VkFlags
type VkMemoryPropertyFlags* = distinct VkFlags
type VkMemoryHeapFlags* = distinct VkFlags
type VkAccessFlags* = distinct VkFlags
type VkBufferUsageFlags* = distinct VkFlags
type VkBufferCreateFlags* = distinct VkFlags
type VkShaderStageFlags* = distinct VkFlags
type VkImageUsageFlags* = distinct VkFlags
type VkImageCreateFlags* = distinct VkFlags
type VkImageViewCreateFlags* = distinct VkFlags
type VkPipelineCreateFlags* = distinct VkFlags
type VkColorComponentFlags* = distinct VkFlags
type VkFenceCreateFlags* = distinct VkFlags
type VkSemaphoreCreateFlags* = distinct VkFlags
type VkFormatFeatureFlags* = distinct VkFlags
type VkQueryControlFlags* = distinct VkFlags
type VkQueryResultFlags* = distinct VkFlags
type VkShaderModuleCreateFlags* = distinct VkFlags
type VkEventCreateFlags* = distinct VkFlags
type VkCommandPoolCreateFlags* = distinct VkFlags
type VkCommandPoolResetFlags* = distinct VkFlags
type VkCommandBufferResetFlags* = distinct VkFlags
type VkCommandBufferUsageFlags* = distinct VkFlags
type VkQueryPipelineStatisticFlags* = distinct VkFlags
type VkMemoryMapFlags* = distinct VkFlags
type VkImageAspectFlags* = distinct VkFlags
type VkSparseMemoryBindFlags* = distinct VkFlags
type VkSparseImageFormatFlags* = distinct VkFlags
type VkSubpassDescriptionFlags* = distinct VkFlags
type VkPipelineStageFlags* = distinct VkFlags
type VkSampleCountFlags* = distinct VkFlags
type VkAttachmentDescriptionFlags* = distinct VkFlags
type VkStencilFaceFlags* = distinct VkFlags
type VkCullModeFlags* = distinct VkFlags
type VkDescriptorPoolCreateFlags* = distinct VkFlags
type VkDescriptorPoolResetFlags* = distinct VkFlags
type VkDependencyFlags* = distinct VkFlags
type VkSubgroupFeatureFlags* = distinct VkFlags
type VkPrivateDataSlotCreateFlags* = distinct VkFlags
type VkDescriptorUpdateTemplateCreateFlags* = distinct VkFlags
type VkPipelineCreationFeedbackFlags* = distinct VkFlags
type VkSemaphoreWaitFlags* = distinct VkFlags
type VkAccessFlags2* = distinct VkFlags64
type VkPipelineStageFlags2* = distinct VkFlags64
type VkFormatFeatureFlags2* = distinct VkFlags64
type VkRenderingFlags* = distinct VkFlags
type VkPeerMemoryFeatureFlags* = distinct VkFlags
type VkMemoryAllocateFlags* = distinct VkFlags
type VkCommandPoolTrimFlags* = distinct VkFlags
type VkExternalMemoryHandleTypeFlags* = distinct VkFlags
type VkExternalMemoryFeatureFlags* = distinct VkFlags
type VkExternalSemaphoreHandleTypeFlags* = distinct VkFlags
type VkExternalSemaphoreFeatureFlags* = distinct VkFlags
type VkSemaphoreImportFlags* = distinct VkFlags
type VkExternalFenceHandleTypeFlags* = distinct VkFlags
type VkExternalFenceFeatureFlags* = distinct VkFlags
type VkFenceImportFlags* = distinct VkFlags
type VkDescriptorBindingFlags* = distinct VkFlags
type VkResolveModeFlags* = distinct VkFlags
type VkToolPurposeFlags* = distinct VkFlags
type VkSubmitFlags* = distinct VkFlags


# Requires
type Display* = ptr object
type VisualID* = ptr object
type Window* = ptr object
type RROutput* = ptr object
type wl_display* = ptr object
type wl_surface* = ptr object
type HINSTANCE* = ptr object
type HWND* = ptr object
type HMONITOR* = ptr object
type HANDLE* = ptr object
type SECURITY_ATTRIBUTES* = ptr object
type DWORD* = ptr object
type LPCWSTR* = ptr object
type xcb_connection_t* = ptr object
type xcb_visualid_t* = ptr object
type xcb_window_t* = ptr object
type IDirectFB* = ptr object
type IDirectFBSurface* = ptr object
type zx_handle_t* = ptr object
type GgpStreamDescriptor* = ptr object
type GgpFrameToken* = ptr object
type screen_context* = ptr object
type screen_window* = ptr object
type screen_buffer* = ptr object
type NvSciSyncAttrList* = ptr object
type NvSciSyncObj* = ptr object
type NvSciSyncFence* = ptr object
type NvSciBufAttrList* = ptr object
type NvSciBufObj* = ptr object
type StdVideoH264ProfileIdc* = ptr object
type StdVideoH264LevelIdc* = ptr object
type StdVideoH264ChromaFormatIdc* = ptr object
type StdVideoH264PocType* = ptr object
type StdVideoH264SpsFlags* = ptr object
type StdVideoH264ScalingLists* = ptr object
type StdVideoH264SequenceParameterSetVui* = ptr object
type StdVideoH264AspectRatioIdc* = ptr object
type StdVideoH264HrdParameters* = ptr object
type StdVideoH264SpsVuiFlags* = ptr object
type StdVideoH264WeightedBipredIdc* = ptr object
type StdVideoH264PpsFlags* = ptr object
type StdVideoH264SliceType* = ptr object
type StdVideoH264CabacInitIdc* = ptr object
type StdVideoH264DisableDeblockingFilterIdc* = ptr object
type StdVideoH264PictureType* = ptr object
type StdVideoH264ModificationOfPicNumsIdc* = ptr object
type StdVideoH264MemMgmtControlOp* = ptr object
type StdVideoDecodeH264PictureInfo* = ptr object
type StdVideoDecodeH264ReferenceInfo* = ptr object
type StdVideoDecodeH264PictureInfoFlags* = ptr object
type StdVideoDecodeH264ReferenceInfoFlags* = ptr object
type StdVideoH264SequenceParameterSet* = ptr object
type StdVideoH264PictureParameterSet* = ptr object
type StdVideoH265ProfileIdc* = ptr object
type StdVideoH265VideoParameterSet* = ptr object
type StdVideoH265SequenceParameterSet* = ptr object
type StdVideoH265PictureParameterSet* = ptr object
type StdVideoH265DecPicBufMgr* = ptr object
type StdVideoH265HrdParameters* = ptr object
type StdVideoH265VpsFlags* = ptr object
type StdVideoH265LevelIdc* = ptr object
type StdVideoH265SpsFlags* = ptr object
type StdVideoH265ScalingLists* = ptr object
type StdVideoH265SequenceParameterSetVui* = ptr object
type StdVideoH265PredictorPaletteEntries* = ptr object
type StdVideoH265PpsFlags* = ptr object
type StdVideoH265SubLayerHrdParameters* = ptr object
type StdVideoH265HrdFlags* = ptr object
type StdVideoH265SpsVuiFlags* = ptr object
type StdVideoH265SliceType* = ptr object
type StdVideoH265PictureType* = ptr object
type StdVideoDecodeH265PictureInfo* = ptr object
type StdVideoDecodeH265ReferenceInfo* = ptr object
type StdVideoDecodeH265PictureInfoFlags* = ptr object
type StdVideoDecodeH265ReferenceInfoFlags* = ptr object
type StdVideoAV1Profile* = ptr object
type StdVideoAV1Level* = ptr object
type StdVideoAV1SequenceHeader* = ptr object
type StdVideoDecodeAV1PictureInfo* = ptr object
type StdVideoDecodeAV1ReferenceInfo* = ptr object
type StdVideoEncodeH264SliceHeader* = ptr object
type StdVideoEncodeH264PictureInfo* = ptr object
type StdVideoEncodeH264ReferenceInfo* = ptr object
type StdVideoEncodeH264SliceHeaderFlags* = ptr object
type StdVideoEncodeH264ReferenceListsInfo* = ptr object
type StdVideoEncodeH264PictureInfoFlags* = ptr object
type StdVideoEncodeH264ReferenceInfoFlags* = ptr object
type StdVideoEncodeH264RefMgmtFlags* = ptr object
type StdVideoEncodeH264RefListModEntry* = ptr object
type StdVideoEncodeH264RefPicMarkingEntry* = ptr object
type StdVideoEncodeH265PictureInfoFlags* = ptr object
type StdVideoEncodeH265PictureInfo* = ptr object
type StdVideoEncodeH265SliceSegmentHeader* = ptr object
type StdVideoEncodeH265ReferenceInfo* = ptr object
type StdVideoEncodeH265ReferenceListsInfo* = ptr object
type StdVideoEncodeH265SliceSegmentHeaderFlags* = ptr object
type StdVideoEncodeH265ReferenceInfoFlags* = ptr object
type StdVideoEncodeH265ReferenceModificationFlags* = ptr object

