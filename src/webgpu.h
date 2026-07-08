#ifndef WEBGPU_H
#define WEBGPU_H 1

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdarg.h>

#undef  WEBGPU_H_MACROS
#undef  WEBGPU_H_ENUMS
#undef  WEBGPU_H_FLAGS
#undef  WEBGPU_H_IMPL
#undef  WEBGPU_H_STRUCTS
#undef  WEBGPU_H_FUNCS

#if     WEBGPU_H_MACROS

typedef uint64_t WGPUFlags;
typedef uint32_t WGPUBool;
typedef uint32_t WGPUBool32;

#define WGPU_TRUE   1
#define WGPU_FALSE  0

#define WGPU_STRLEN (SIZE_MAX)

#endif  // WEBGPU_H_MACROS
#if     WEBGPU_H_ENUMS

// Integer values ARE NOT those used in other implementations

typedef enum WGPUAdapterType {
    WGPUAdapterType_Unknown = 0x00000000,
    WGPUAdapterType_DiscreteGPU = 0x00000001,
    WGPUAdapterType_IntegratedGPU = 0x00000002,
    WGPUAdapterType_CPU = 0x00000003,
} WGPUAdapterType;

typedef enum WGPUAddressMode {
    WGPUAddressMode_ClampToEdge = 0x00000001,
} WGPUAddressMode;

typedef enum WGPUBackendType {
    WGPUBackendType_WebGPU = 0x00000001,
    WGPUBackendType_D3D11 = 0x00000002,
    WGPUBackendType_D3D12 = 0x00000003,
    WGPUBackendType_Metal = 0x00000004,
    WGPUBackendType_Vulkan = 0x00000005,
    WGPUBackendType_OpenGL = 0x00000006,
    WGPUBackendType_OpenGLES = 0x00000007,
} WGPUBackendType;

typedef enum WGPUBlendFactor {
    WGPUBlendFactor_Zero = 0x00000001,
    WGPUBlendFactor_One = 0x00000002,
    WGPUBlendFactor_SrcAlpha = 0x00000003,
    WGPUBlendFactor_OneMinusSrcAlpha = 0x00000004,
} WGPUBlendFactor;

typedef enum WGPUBlendOperation {
    WGPUBlendOperation_Add = 0x00000001,
} WGPUBlendOperation;

typedef enum WGPUBufferBindingType {
    WGPUBufferBindingType_Uniform = 0x00000001,
} WGPUBufferBindingType;

typedef enum WGPUCallbackMode {
    WGPUCallbackMode_AllowSpontaneous = 0x00000001,
} WGPUCallbackMode;

typedef enum WGPUCompareFunction {
    WGPUCompareFunction_Always = 0x00000001,
} WGPUCompareFunction;

typedef enum WGPULoadOp {
    WGPULoadOp_Load = 0x00000001,
    WGPULoadOp_Clear = 0x00000002,
} WGPULoadOp;

typedef enum WGPUCullMode {
    WGPUCullMode_None = 0x00000001,
} WGPUCullMode;

typedef enum WGPUDeviceLostReason {
    WGPUDeviceLostReason_Unknown = 0x00000001,
    WGPUDeviceLostReason_Destroyed = 0x00000002,
    WGPUDeviceLostReason_CallbackCancelled = 0x00000003,
    WGPUDeviceLostReason_FailedCreation = 0x00000004,
} WGPUDeviceLostReason;

typedef enum WGPUErrorFilter {
    WGPUErrorFilter_Validation = 0x00000001,
} WGPUErrorFilter;

typedef enum WGPUErrorType {
    WGPUErrorType_Validation = 0x00000001,
    WGPUErrorType_OutOfMemory = 0x00000002,
    WGPUErrorType_Internal = 0x00000003,
    WGPUErrorType_Unknown = 0x00000004,
} WGPUErrorType;

typedef enum WGPUFilterMode {
    WGPUFilterMode_Nearest = 0x00000001,
    WGPUFilterMode_Linear = 0x00000002,
} WGPUFilterMode;

typedef enum WGPUFrontFace {
    WGPUFrontFace_CCW = 0x00000001,
    WGPUFrontFace_CW = 0x00000002,
} WGPUFrontFace;

typedef enum WGPUIndexFormat {
    WGPUIndexFormat_Undefined = 0x00000000,
    WGPUIndexFormat_Uint16 = 0x00000001,
    WGPUIndexFormat_Uint32 = 0x00000002,
} WGPUIndexFormat;

typedef enum WGPUMipmapFilterMode {
    WGPUMipmapFilterMode_Nearest = 0x00000001,
    WGPUMipmapFilterMode_Linear = 0x00000002,
} WGPUMipmapFilterMode;

typedef enum WGPUOptionalBool {
    WGPUOptionalBool_False = 0x00000000,
} WGPUOptionalBool;

typedef enum WGPUPopErrorScopeStatus {
    WGPUPopErrorScopeStatus_Success = 0x00000001,
} WGPUPopErrorScopeStatus;

typedef enum WGPUPrimitiveTopology {
    WGPUPrimitiveTopology_TriangleList = 0x00000001,
} WGPUPrimitiveTopology;

typedef enum WGPUSamplerBindingType {
    WGPUSamplerBindingType_Filtering = 0x00000001,
} WGPUSamplerBindingType;

typedef enum WGPUShaderStageEnum {
    WGPUShaderStageEnum_Vertex,
    WGPUShaderStageEnum_Fragment,
} WGPUShaderStageEnum;

typedef enum WGPUStatus {
    WGPUStatus_Success = 0x00000001,
    WGPUStatus_Error = 0x00000002,
} WGPUStatus;

typedef enum WGPUStencilOperation {
    WGPUStencilOperation_Keep = 0x00000001,
} WGPUStencilOperation;

typedef enum WGPUStoreOp {
    WGPUStoreOp_Store = 0x00000001,
} WGPUStoreOp;

typedef enum WGPUSType {
    WGPUSType_ShaderSourceSPIRV = 0x00000001,
    WGPUSType_ShaderSourceWGSL = 0x00000002,
} WGPUSType;

typedef enum WGPUSurfaceGetCurrentTextureStatus {
    WGPUSurfaceGetCurrentTextureStatus_SuccessSuboptimal = 0x00000001,
    WGPUSurfaceGetCurrentTextureStatus_Timeout = 0x00000002,
    WGPUSurfaceGetCurrentTextureStatus_Outdated = 0x00000003,
    WGPUSurfaceGetCurrentTextureStatus_Lost = 0x00000004,
    WGPUSurfaceGetCurrentTextureStatus_Error = 0x00000005,
} WGPUSurfaceGetCurrentTextureStatus;

typedef enum WGPUTextureAspect {
    WGPUTextureAspect_All = 0x00000001,
} WGPUTextureAspect;

typedef enum WGPUTextureDimension {
    WGPUTextureDimension_2D = 0x00000001,
} WGPUTextureDimension;

typedef enum WGPUTextureFormat {
    WGPUTextureFormat_Undefined = 0x00000000,
    WGPUTextureFormat_R8Unorm = 0x00000001,
    WGPUTextureFormat_R8Snorm = 0x00000002,
    WGPUTextureFormat_R8Uint = 0x00000003,
    WGPUTextureFormat_R8Sint = 0x00000004,
    WGPUTextureFormat_R16Unorm = 0x00000005,
    WGPUTextureFormat_R16Snorm = 0x00000006,
    WGPUTextureFormat_R16Uint = 0x00000007,
    WGPUTextureFormat_R16Sint = 0x00000008,
    WGPUTextureFormat_R16Float = 0x00000009,
    WGPUTextureFormat_RG8Unorm = 0x0000000A,
    WGPUTextureFormat_RG8Snorm = 0x0000000B,
    WGPUTextureFormat_RG8Uint = 0x0000000C,
    WGPUTextureFormat_RG8Sint = 0x0000000D,
    WGPUTextureFormat_R32Float = 0x0000000E,
    WGPUTextureFormat_R32Uint = 0x0000000F,
    WGPUTextureFormat_R32Sint = 0x00000010,
    WGPUTextureFormat_RG16Unorm = 0x00000011,
    WGPUTextureFormat_RG16Snorm = 0x00000012,
    WGPUTextureFormat_RG16Uint = 0x00000013,
    WGPUTextureFormat_RG16Sint = 0x00000014,
    WGPUTextureFormat_RG16Float = 0x00000015,
    WGPUTextureFormat_RGBA8Unorm = 0x00000016,
    WGPUTextureFormat_RGBA8UnormSrgb = 0x00000017,
    WGPUTextureFormat_RGBA8Snorm = 0x00000018,
    WGPUTextureFormat_RGBA8Uint = 0x00000019,
    WGPUTextureFormat_RGBA8Sint = 0x0000001A,
    WGPUTextureFormat_BGRA8Unorm = 0x0000001B,
    WGPUTextureFormat_BGRA8UnormSrgb = 0x0000001C,
    WGPUTextureFormat_RGB10A2Uint = 0x0000001D,
    WGPUTextureFormat_RGB10A2Unorm = 0x0000001E,
    WGPUTextureFormat_RG11B10Ufloat = 0x0000001F,
    WGPUTextureFormat_RGB9E5Ufloat = 0x00000020,
    WGPUTextureFormat_RG32Float = 0x00000021,
    WGPUTextureFormat_RG32Uint = 0x00000022,
    WGPUTextureFormat_RG32Sint = 0x00000023,
    WGPUTextureFormat_RGBA16Unorm = 0x00000024,
    WGPUTextureFormat_RGBA16Snorm = 0x00000025,
    WGPUTextureFormat_RGBA16Uint = 0x00000026,
    WGPUTextureFormat_RGBA16Sint = 0x00000027,
    WGPUTextureFormat_RGBA16Float = 0x00000028,
    WGPUTextureFormat_RGBA32Float = 0x00000029,
    WGPUTextureFormat_RGBA32Uint = 0x0000002A,
    WGPUTextureFormat_RGBA32Sint = 0x0000002B,
    WGPUTextureFormat_Stencil8 = 0x0000002C,
    WGPUTextureFormat_Depth16Unorm = 0x0000002D,
    WGPUTextureFormat_Depth24Plus = 0x0000002E,
    WGPUTextureFormat_Depth24PlusStencil8 = 0x0000002F,
    WGPUTextureFormat_Depth32Float = 0x00000030,
    WGPUTextureFormat_Depth32FloatStencil8 = 0x00000031,
    WGPUTextureFormat_BC1RGBAUnorm = 0x00000032,
    WGPUTextureFormat_BC1RGBAUnormSrgb = 0x00000033,
    WGPUTextureFormat_BC2RGBAUnorm = 0x00000034,
    WGPUTextureFormat_BC2RGBAUnormSrgb = 0x00000035,
    WGPUTextureFormat_BC3RGBAUnorm = 0x00000036,
    WGPUTextureFormat_BC3RGBAUnormSrgb = 0x00000037,
    WGPUTextureFormat_BC4RUnorm = 0x00000038,
    WGPUTextureFormat_BC4RSnorm = 0x00000039,
    WGPUTextureFormat_BC5RGUnorm = 0x0000003A,
    WGPUTextureFormat_BC5RGSnorm = 0x0000003B,
    WGPUTextureFormat_BC6HRGBUfloat = 0x0000003C,
    WGPUTextureFormat_BC6HRGBFloat = 0x0000003D,
    WGPUTextureFormat_BC7RGBAUnorm = 0x0000003E,
    WGPUTextureFormat_BC7RGBAUnormSrgb = 0x0000003F,
    WGPUTextureFormat_ETC2RGB8Unorm = 0x00000040,
    WGPUTextureFormat_ETC2RGB8UnormSrgb = 0x00000041,
    WGPUTextureFormat_ETC2RGB8A1Unorm = 0x00000042,
    WGPUTextureFormat_ETC2RGB8A1UnormSrgb = 0x00000043,
    WGPUTextureFormat_ETC2RGBA8Unorm = 0x00000044,
    WGPUTextureFormat_ETC2RGBA8UnormSrgb = 0x00000045,
    WGPUTextureFormat_EACR11Unorm = 0x00000046,
    WGPUTextureFormat_EACR11Snorm = 0x00000047,
    WGPUTextureFormat_EACRG11Unorm = 0x00000048,
    WGPUTextureFormat_EACRG11Snorm = 0x00000049,
    WGPUTextureFormat_ASTC4x4Unorm = 0x0000004A,
    WGPUTextureFormat_ASTC4x4UnormSrgb = 0x0000004B,
    WGPUTextureFormat_ASTC5x4Unorm = 0x0000004C,
    WGPUTextureFormat_ASTC5x4UnormSrgb = 0x0000004D,
    WGPUTextureFormat_ASTC5x5Unorm = 0x0000004E,
    WGPUTextureFormat_ASTC5x5UnormSrgb = 0x0000004F,
    WGPUTextureFormat_ASTC6x5Unorm = 0x00000050,
    WGPUTextureFormat_ASTC6x5UnormSrgb = 0x00000051,
    WGPUTextureFormat_ASTC6x6Unorm = 0x00000052,
    WGPUTextureFormat_ASTC6x6UnormSrgb = 0x00000053,
    WGPUTextureFormat_ASTC8x5Unorm = 0x00000054,
    WGPUTextureFormat_ASTC8x5UnormSrgb = 0x00000055,
    WGPUTextureFormat_ASTC8x6Unorm = 0x00000056,
    WGPUTextureFormat_ASTC8x6UnormSrgb = 0x00000057,
    WGPUTextureFormat_ASTC8x8Unorm = 0x00000058,
    WGPUTextureFormat_ASTC8x8UnormSrgb = 0x00000059,
    WGPUTextureFormat_ASTC10x5Unorm = 0x0000005A,
    WGPUTextureFormat_ASTC10x5UnormSrgb = 0x0000005B,
    WGPUTextureFormat_ASTC10x6Unorm = 0x0000005C,
    WGPUTextureFormat_ASTC10x6UnormSrgb = 0x0000005D,
    WGPUTextureFormat_ASTC10x8Unorm = 0x0000005E,
    WGPUTextureFormat_ASTC10x8UnormSrgb = 0x0000005F,
    WGPUTextureFormat_ASTC10x10Unorm = 0x00000060,
    WGPUTextureFormat_ASTC10x10UnormSrgb = 0x00000061,
    WGPUTextureFormat_ASTC12x10Unorm = 0x00000062,
    WGPUTextureFormat_ASTC12x10UnormSrgb = 0x00000063,
    WGPUTextureFormat_ASTC12x12Unorm = 0x00000064,
    WGPUTextureFormat_ASTC12x12UnormSrgb = 0x00000065,
} WGPUTextureFormat;

typedef enum WGPUTextureSampleType {
    WGPUTextureSampleType_Float = 0x00000001,
} WGPUTextureSampleType;

typedef enum WGPUTextureViewDimension {
    WGPUTextureViewDimension_2D = 0x00000001,
    WGPUTextureViewDimension_2DArray = 0x00000002,
} WGPUTextureViewDimension;

typedef enum WGPUVertexFormat {
    WGPUVertexFormat_Unorm8x4 = 0x00000001,
    WGPUVertexFormat_Float32x2 = 0x00000002,
} WGPUVertexFormat;

typedef enum WGPUVertexStepMode {
    WGPUVertexStepMode_Vertex = 0x00000001,
} WGPUVertexStepMode;

#endif  // WEBGPU_H_ENUMS
#if     WEBGPU_H_FLAGS

// Integer values NEED to be the same than values used in other implementations

typedef WGPUFlags WGPUBufferUsage;
static const WGPUBufferUsage WGPUBufferUsage_CopyDst = 0x0000000000000008;
static const WGPUBufferUsage WGPUBufferUsage_Index = 0x0000000000000010;
static const WGPUBufferUsage WGPUBufferUsage_Vertex = 0x0000000000000020;
static const WGPUBufferUsage WGPUBufferUsage_Uniform = 0x0000000000000040;

typedef WGPUFlags WGPUColorWriteMask;
static const WGPUColorWriteMask WGPUColorWriteMask_All = 0x000000000000000F;

typedef WGPUFlags WGPUTextureUsage;
static const WGPUTextureUsage WGPUTextureUsage_CopyDst = 0x0000000000000002;
static const WGPUTextureUsage WGPUTextureUsage_TextureBinding = 0x0000000000000004;
static const WGPUTextureUsage WGPUTextureUsage_RenderAttachment = 0x0000000000000010;

typedef WGPUFlags WGPUShaderStage;
static const WGPUShaderStage WGPUShaderStage_Vertex = (((WGPUFlags)1) << WGPUShaderStageEnum_Vertex);
static const WGPUShaderStage WGPUShaderStage_Fragment = (((WGPUFlags)1) << WGPUShaderStageEnum_Fragment);

#endif  // WEBGPU_H_FLAGS
#if     WEBGPU_H_IMPL

struct WGPUAdapterImpl;
typedef struct WGPUAdapterImpl* WGPUAdapter;

struct WGPUBindGroupImpl;
typedef struct WGPUBindGroupImpl* WGPUBindGroup;

struct WGPUBindGroupLayoutImpl;
typedef struct WGPUBindGroupLayoutImpl* WGPUBindGroupLayout;

struct WGPUBufferImpl;
typedef struct WGPUBufferImpl* WGPUBuffer;

struct WGPUDeviceImpl;
typedef struct WGPUDeviceImpl* WGPUDevice;

struct WGPUInstanceImpl;
typedef struct WGPUInstanceImpl* WGPUInstance;

struct WGPUPipelineLayoutImpl;
typedef struct WGPUPipelineLayoutImpl* WGPUPipelineLayout;

struct WGPUQueueImpl;
typedef struct WGPUQueueImpl* WGPUQueue;

struct WGPURenderPassEncoderImpl;
typedef struct WGPURenderPassEncoderImpl* WGPURenderPassEncoder;

struct WGPURenderPipelineImpl;
typedef struct WGPURenderPipelineImpl* WGPURenderPipeline;

struct WGPUSamplerImpl;
typedef struct WGPUSamplerImpl* WGPUSampler;

struct WGPUShaderModuleImpl;
typedef struct WGPUShaderModuleImpl* WGPUShaderModule;

struct WGPUSurfaceImpl;
typedef struct WGPUSurfaceImpl* WGPUSurface;

struct WGPUTextureImpl;
typedef struct WGPUTextureImpl* WGPUTexture;

struct WGPUTextureViewImpl;
typedef struct WGPUTextureViewImpl* WGPUTextureView;

#endif  // WEBGPU_H_IMPL
#if     WEBGPU_H_STRUCTS

typedef struct WGPUChainedStruct {
    struct WGPUChainedStruct* next;
    WGPUSType sType;
} WGPUChainedStruct;

typedef struct WGPUStringView {
    const char* data;
    size_t length;
} WGPUStringView;

typedef struct WGPUComputeState {
    WGPUShaderModule module;
    WGPUStringView entryPoint;
} WGPUComputeState;

typedef struct WGPUMultisampleState {
    uint32_t count;
    uint32_t mask;
    WGPUBool32 alphaToCoverageEnabled;
} WGPUMultisampleState;

typedef struct WGPUShaderModuleDescriptor {
    WGPUChainedStruct* nextInChain;
} WGPUShaderModuleDescriptor;

typedef struct WGPUShaderSourceSPIRV {
    WGPUChainedStruct chain;
    uint32_t codeSize;
    const uint32_t* code;
} WGPUShaderSourceSPIRV;

typedef struct WGPUShaderSourceWGSL {
    WGPUChainedStruct chain;
    WGPUStringView code;
} WGPUShaderSourceWGSL;

typedef struct WGPUBindGroupEntry {
    WGPUChainedStruct* nextInChain;
    uint32_t binding;
    WGPUBuffer buffer;
    uint64_t offset;
    uint64_t size;
    WGPUSampler sampler;
    WGPUTextureView textureView;
} WGPUBindGroupEntry;

typedef struct WGPUBindGroupDescriptor {
    WGPUBindGroupLayout layout;
    size_t entryCount;
    const WGPUBindGroupEntry* entries;
} WGPUBindGroupDescriptor;

typedef void (*WGPUPopErrorScopeCallback)(WGPUPopErrorScopeStatus, WGPUErrorType, WGPUStringView, void*, void*);

typedef struct WGPUPopErrorScopeCallbackInfo {
    WGPUCallbackMode mode;
    WGPUPopErrorScopeCallback callback;
    void* userdata1;
} WGPUPopErrorScopeCallbackInfo;

typedef struct WGPUFuture {
    uint64_t id;
} WGPUFuture;

typedef struct WGPUColor {
    double r;
    double g;
    double b;
    double a;
} WGPUColor;

typedef struct WGPUBufferDescriptor {
    WGPUChainedStruct* nextInChain;
    WGPUStringView label;
    WGPUBufferUsage usage;
    uint64_t size;
    WGPUBool mappedAtCreation;
} WGPUBufferDescriptor;

typedef struct WGPUExtent3D {
    uint32_t width;
    uint32_t height;
    uint32_t depthOrArrayLayers;
} WGPUExtent3D;

typedef struct WGPUTextureDescriptor {
    WGPUStringView label;
    WGPUTextureUsage usage;
    WGPUTextureDimension dimension;
    WGPUExtent3D size;
    WGPUTextureFormat format;
    uint32_t mipLevelCount;
    uint32_t sampleCount;
} WGPUTextureDescriptor;

typedef struct WGPUTextureViewDescriptor {
    WGPUTextureFormat format;
    WGPUTextureViewDimension dimension;
    uint32_t baseMipLevel;
    uint32_t mipLevelCount;
    uint32_t baseArrayLayer;
    uint32_t arrayLayerCount;
    WGPUTextureAspect aspect;
} WGPUTextureViewDescriptor;

typedef struct WGPUOrigin3D {
    uint32_t x;
    uint32_t y;
    uint32_t z;
} WGPUOrigin3D;

typedef struct WGPUTexelCopyTextureInfo {
    WGPUTexture texture;
    uint32_t mipLevel;
    WGPUOrigin3D origin;
    WGPUTextureAspect aspect;
} WGPUTexelCopyTextureInfo;

typedef struct WGPUTexelCopyBufferLayout {
    uint64_t offset;
    uint32_t bytesPerRow;
    uint32_t rowsPerImage;
} WGPUTexelCopyBufferLayout;

typedef struct WGPUPrimitiveState {
    WGPUPrimitiveTopology topology;
    WGPUIndexFormat stripIndexFormat;
    WGPUFrontFace frontFace;
    WGPUCullMode cullMode;
} WGPUPrimitiveState;

typedef struct WGPUBlendComponent {
    WGPUBlendOperation operation;
    WGPUBlendFactor srcFactor;
    WGPUBlendFactor dstFactor;
} WGPUBlendComponent;

typedef struct WGPUBlendState {
    WGPUBlendComponent color;
    WGPUBlendComponent alpha;
} WGPUBlendState;

typedef struct WGPUVertexAttribute {
    WGPUChainedStruct* nextInChain;
    WGPUVertexFormat format;
    uint64_t offset;
    uint32_t shaderLocation;
} WGPUVertexAttribute;

typedef struct WGPUVertexBufferLayout {
    WGPUVertexStepMode stepMode;
    uint64_t arrayStride;
    size_t attributeCount;
    const WGPUVertexAttribute* attributes;
} WGPUVertexBufferLayout;

typedef struct WGPUVertexState {
    WGPUShaderModule module;
    WGPUStringView entryPoint;
    size_t bufferCount;
    const WGPUVertexBufferLayout* buffers;
} WGPUVertexState;

typedef struct WGPUColorTargetState {
    WGPUTextureFormat format;
    const WGPUBlendState* blend;
    WGPUColorWriteMask writeMask;
} WGPUColorTargetState;

typedef struct WGPUFragmentState {
    WGPUShaderModule module;
    WGPUStringView entryPoint;
    size_t targetCount;
    const WGPUColorTargetState* targets;
} WGPUFragmentState;

typedef struct WGPUStencilFaceState {
    WGPUCompareFunction compare;
    WGPUStencilOperation failOp;
    WGPUStencilOperation depthFailOp;
    WGPUStencilOperation passOp;
} WGPUStencilFaceState;

typedef struct WGPUDepthStencilState {
    WGPUTextureFormat format;
    WGPUOptionalBool depthWriteEnabled;
    WGPUCompareFunction depthCompare;
    WGPUStencilFaceState stencilFront;
    WGPUStencilFaceState stencilBack;
} WGPUDepthStencilState;

typedef struct WGPURenderPipelineDescriptor {
    WGPUPipelineLayout layout;
    WGPUVertexState vertex;
    WGPUPrimitiveState primitive;
    const WGPUDepthStencilState* depthStencil;
    WGPUMultisampleState multisample;
    const WGPUFragmentState* fragment;
} WGPURenderPipelineDescriptor;

typedef struct WGPUBufferBindingLayout {
    WGPUBufferBindingType type;
} WGPUBufferBindingLayout;

typedef struct WGPUSamplerBindingLayout {
    WGPUSamplerBindingType type;
} WGPUSamplerBindingLayout;

typedef struct WGPUTextureBindingLayout {
    WGPUTextureSampleType sampleType;
    WGPUTextureViewDimension viewDimension;
} WGPUTextureBindingLayout;

typedef struct WGPUBindGroupLayoutEntry {
    uint32_t binding;
    WGPUShaderStage visibility;
    WGPUBufferBindingLayout buffer;
    WGPUSamplerBindingLayout sampler;
    WGPUTextureBindingLayout texture;
} WGPUBindGroupLayoutEntry;

typedef struct WGPUBindGroupLayoutDescriptor {
    size_t entryCount;
    WGPUBindGroupLayoutEntry const * entries;
} WGPUBindGroupLayoutDescriptor;

typedef struct WGPUPipelineLayoutDescriptor {
    size_t bindGroupLayoutCount;
    const WGPUBindGroupLayout * bindGroupLayouts;
} WGPUPipelineLayoutDescriptor;

typedef struct WGPUSamplerDescriptor {
    WGPUAddressMode addressModeU;
    WGPUAddressMode addressModeV;
    WGPUAddressMode addressModeW;
    WGPUFilterMode magFilter;
    WGPUFilterMode minFilter;
    WGPUMipmapFilterMode mipmapFilter;
    uint16_t maxAnisotropy;
} WGPUSamplerDescriptor;

typedef struct WGPUSurfaceDescriptor {} WGPUSurfaceDescriptor;

typedef struct WGPUAdapterInfo {
    WGPUStringView description;
    WGPUStringView vendor;
    uint32_t vendorID;
    WGPUStringView architecture;
    WGPUStringView device;
    uint32_t deviceID;
    WGPUAdapterType adapterType;
    WGPUBackendType backendType;
} WGPUAdapterInfo;

#endif  // WEBGPU_H_STRUCTS
#if     WEBGPU_H_FUNCS

extern WGPUStatus          webgpuImpl_adapterGetInfo(WGPUAdapter, WGPUAdapterInfo*);
extern void                webgpuImpl_adapterInfoFreeMembers(WGPUAdapterInfo);
extern void                webgpuImpl_bindGroupLayoutRelease(WGPUBindGroupLayout);
extern void                webgpuImpl_bindGroupRelease(WGPUBindGroup);
extern void                webgpuImpl_bufferDestroy(WGPUBuffer);
extern void                webgpuImpl_bufferRelease(WGPUBuffer);
extern WGPUBindGroup       webgpuImpl_deviceCreateBindGroup(WGPUDevice, const WGPUBindGroupDescriptor*);
extern WGPUBindGroupLayout webgpuImpl_deviceCreateBindGroupLayout(WGPUDevice, const WGPUBindGroupLayoutDescriptor*);
extern WGPUBuffer          webgpuImpl_deviceCreateBuffer(WGPUDevice, const WGPUBufferDescriptor*);
extern WGPUPipelineLayout  webgpuImpl_deviceCreatePipelineLayout(WGPUDevice, const WGPUPipelineLayoutDescriptor*);
extern WGPURenderPipeline  webgpuImpl_deviceCreateRenderPipeline(WGPUDevice, const WGPURenderPipelineDescriptor*);
extern WGPUSampler         webgpuImpl_deviceCreateSampler(WGPUDevice, const WGPUSamplerDescriptor*);
extern WGPUShaderModule    webgpuImpl_deviceCreateShaderModule(WGPUDevice, const WGPUShaderModuleDescriptor*);
extern WGPUTexture         webgpuImpl_deviceCreateTexture(WGPUDevice, const WGPUTextureDescriptor*);
extern WGPUQueue           webgpuImpl_deviceGetQueue(WGPUDevice);
extern WGPUFuture          webgpuImpl_devicePopErrorScope(WGPUDevice, WGPUPopErrorScopeCallbackInfo);
extern void                webgpuImpl_devicePushErrorScope(WGPUDevice, WGPUErrorFilter);
extern void                webgpuImpl_pipelineLayoutRelease(WGPUPipelineLayout);
extern void                webgpuImpl_queueRelease(WGPUQueue);
extern void                webgpuImpl_queueWriteBuffer(WGPUQueue, WGPUBuffer, uint64_t, const void*, size_t);
extern void                webgpuImpl_queueWriteTexture(WGPUQueue, WGPUTexelCopyTextureInfo const*, const void*, size_t, WGPUTexelCopyBufferLayout const*, WGPUExtent3D const*);
extern void                webgpuImpl_renderPassEncoderDrawIndexed(WGPURenderPassEncoder, uint32_t, uint32_t, uint32_t, int32_t, uint32_t);
extern void                webgpuImpl_renderPassEncoderSetBindGroup(WGPURenderPassEncoder, uint32_t, WGPUBindGroup, size_t, uint32_t const*);
extern void                webgpuImpl_renderPassEncoderSetBlendConstant(WGPURenderPassEncoder, WGPUColor const*);
extern void                webgpuImpl_renderPassEncoderSetIndexBuffer(WGPURenderPassEncoder, WGPUBuffer, WGPUIndexFormat, uint64_t, uint64_t);
extern void                webgpuImpl_renderPassEncoderSetPipeline(WGPURenderPassEncoder, WGPURenderPipeline);
extern void                webgpuImpl_renderPassEncoderSetScissorRect(WGPURenderPassEncoder, uint32_t, uint32_t, uint32_t, uint32_t);
extern void                webgpuImpl_renderPassEncoderSetVertexBuffer(WGPURenderPassEncoder, uint32_t, WGPUBuffer, uint64_t, uint64_t);
extern void                webgpuImpl_renderPassEncoderSetViewport(WGPURenderPassEncoder, float, float, float, float, float, float);
extern void                webgpuImpl_renderPipelineRelease(WGPURenderPipeline);
extern void                webgpuImpl_samplerRelease(WGPUSampler);
extern void                webgpuImpl_shaderModuleRelease(WGPUShaderModule);
extern WGPUTextureView     webgpuImpl_textureCreateView(WGPUTexture, const WGPUTextureViewDescriptor*);
extern void                webgpuImpl_textureRelease(WGPUTexture);
extern void                webgpuImpl_textureViewRelease(WGPUTextureView);

#include "trace.h"

#define wgpuAdapterGetInfo(...)                    TRACE(webgpuImpl_adapterGetInfo, __VA_ARGS__)
#define wgpuAdapterInfoFreeMembers(...)            TRACE(webgpuImpl_adapterInfoFreeMembers, __VA_ARGS__)
#define wgpuBindGroupLayoutRelease(...)            TRACE(webgpuImpl_bindGroupLayoutRelease, __VA_ARGS__)
#define wgpuBindGroupRelease(...)                  TRACE(webgpuImpl_bindGroupRelease, __VA_ARGS__)
#define wgpuBufferDestroy(...)                     TRACE(webgpuImpl_bufferDestroy, __VA_ARGS__)
#define wgpuBufferRelease(...)                     TRACE(webgpuImpl_bufferRelease, __VA_ARGS__)
#define wgpuDeviceCreateBindGroup(...)             TRACE(webgpuImpl_deviceCreateBindGroup, __VA_ARGS__)
#define wgpuDeviceCreateBindGroupLayout(...)       TRACE(webgpuImpl_deviceCreateBindGroupLayout, __VA_ARGS__)
#define wgpuDeviceCreateBuffer(...)                TRACE(webgpuImpl_deviceCreateBuffer, __VA_ARGS__)
#define wgpuDeviceCreatePipelineLayout(...)        TRACE(webgpuImpl_deviceCreatePipelineLayout, __VA_ARGS__)
#define wgpuDeviceCreateRenderPipeline(...)        TRACE(webgpuImpl_deviceCreateRenderPipeline, __VA_ARGS__)
#define wgpuDeviceCreateSampler(...)               TRACE(webgpuImpl_deviceCreateSampler, __VA_ARGS__)
#define wgpuDeviceCreateShaderModule(...)          TRACE(webgpuImpl_deviceCreateShaderModule, __VA_ARGS__)
#define wgpuDeviceCreateTexture(...)               TRACE(webgpuImpl_deviceCreateTexture, __VA_ARGS__)
#define wgpuDeviceGetQueue(...)                    TRACE(webgpuImpl_deviceGetQueue, __VA_ARGS__)
#define wgpuDevicePopErrorScope(...)               TRACE(webgpuImpl_devicePopErrorScope, __VA_ARGS__)
#define wgpuDevicePushErrorScope(...)              TRACE(webgpuImpl_devicePushErrorScope, __VA_ARGS__)
#define wgpuPipelineLayoutRelease(...)             TRACE(webgpuImpl_pipelineLayoutRelease, __VA_ARGS__)
#define wgpuQueueRelease(...)                      TRACE(webgpuImpl_queueRelease, __VA_ARGS__)
#define wgpuQueueWriteBuffer(...)                  TRACE(webgpuImpl_queueWriteBuffer, __VA_ARGS__)
#define wgpuQueueWriteTexture(...)                 TRACE(webgpuImpl_queueWriteTexture, __VA_ARGS__)
#define wgpuRenderPassEncoderDrawIndexed(...)      TRACE(webgpuImpl_renderPassEncoderDrawIndexed, __VA_ARGS__)
#define wgpuRenderPassEncoderSetBindGroup(...)     TRACE(webgpuImpl_renderPassEncoderSetBindGroup, __VA_ARGS__)
#define wgpuRenderPassEncoderSetBlendConstant(...) TRACE(webgpuImpl_renderPassEncoderSetBlendConstant, __VA_ARGS__)
#define wgpuRenderPassEncoderSetIndexBuffer(...)   TRACE(webgpuImpl_renderPassEncoderSetIndexBuffer, __VA_ARGS__)
#define wgpuRenderPassEncoderSetPipeline(...)      TRACE(webgpuImpl_renderPassEncoderSetPipeline, __VA_ARGS__)
#define wgpuRenderPassEncoderSetScissorRect(...)   TRACE(webgpuImpl_renderPassEncoderSetScissorRect, __VA_ARGS__)
#define wgpuRenderPassEncoderSetVertexBuffer(...)  TRACE(webgpuImpl_renderPassEncoderSetVertexBuffer, __VA_ARGS__)
#define wgpuRenderPassEncoderSetViewport(...)      TRACE(webgpuImpl_renderPassEncoderSetViewport, __VA_ARGS__)
#define wgpuRenderPipelineRelease(...)             TRACE(webgpuImpl_renderPipelineRelease, __VA_ARGS__)
#define wgpuSamplerRelease(...)                    TRACE(webgpuImpl_samplerRelease, __VA_ARGS__)
#define wgpuShaderModuleRelease(...)               TRACE(webgpuImpl_shaderModuleRelease, __VA_ARGS__)
#define wgpuTextureCreateView(...)                 TRACE(webgpuImpl_textureCreateView, __VA_ARGS__)
#define wgpuTextureRelease(...)                    TRACE(webgpuImpl_textureRelease, __VA_ARGS__)
#define wgpuTextureViewRelease(...)                TRACE(webgpuImpl_textureViewRelease, __VA_ARGS__)

#endif  // WEBGPU_H_FUNCS

#ifdef __cplusplus
}
#endif

#endif  // WEBGPU_H
