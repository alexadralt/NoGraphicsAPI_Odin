package gpu

uint32x2 :: struct { x, y : u32 }
uint32x3 :: struct { x, y, z : u32 }

Device            :: struct {}
Texture           :: struct {}
RenderView        :: struct {}
PSO               :: struct {}
CommandBuffer     :: struct {}
TimelineSemaphore :: struct {}
GpuHeapOwner      :: struct {}
TextureHeapOwner  :: struct {}

Error :: enum u8 {
    none = 0,
    unsupported,
    device_lost,
    driver_error,
}

MemoryType :: enum u8 {
    cpu_visible,
    gpu_only,
    readback,
    texture_descriptor_heap,
    sampler_descriptor_heap,
}

SizeAlign :: struct {
    size  : u64,
    align : u64,
}

GpuRange :: struct {
    gpu  : [^]u8,
    size : u64,
}

GpuCpuRange :: struct($T : typeid) {
    cpu  : [^]T,
    gpu  : [^]T,
    size : u64, // Bytes, independent of T.
}

GpuHeap :: struct {
    // Copies alias the same allocation. Pass one unchanged copy to destroy_gpu_heap exactly once.
    range : GpuCpuRange(u8),
    owner : ^GpuHeapOwner,
}

@(require_results) gpu_range_from_GpuCpuRange :: proc(range : GpuCpuRange($T)) -> GpuRange {
    return {gpu = range.gpu, size = range.size}
}

@(require_results) gpu_range_from_GpuHeap :: proc(heap : GpuHeap) -> GpuRange {
    return gpu_range(heap.range)
}

gpu_range :: proc{gpu_range_from_GpuCpuRange, gpu_range_from_GpuHeap}

TextureHeap :: struct {
    // Copies alias the same allocation. Pass one unchanged copy to destroy_texture_heap exactly once.
    size  : u64,
    owner : ^TextureHeapOwner,
}

TimelinePoint :: struct {
    semaphore : ^TimelineSemaphore,
    value     : u64,
}

Format :: enum u8 {
    r8_srgb,
    rg8_srgb,
    rgba8_srgb,
    bgra8_srgb,

    rgba4_unorm,
    r5g5b5a1_unorm,
    r5g6b5_unorm,

    r8_unorm,
    rg8_unorm,
    rgba8_unorm,
    bgra8_unorm,
    r16_unorm,
    rg16_unorm,
    rgba16_unorm,

    r8_uint,
    rg8_uint,
    rgba8_uint,
    bgra8_uint,
    r16_uint,
    rg16_uint,
    rgba16_uint,
    r32_uint,
    rg32_uint,
    rgb32_uint,
    rgba32_uint,

    r16_float,
    rg16_float,
    rgba16_float,
    r32_float,
    rg32_float,
    rgb32_float,
    rgba32_float,

    rgb10a2_unorm,
    rg11b10_float,

    d16_unorm,
    d24_unorm_s8_uint,
    d32_float,
    s8_uint,
    d32_float_s8_uint,

    eac_rg,
    astc_4x4_srgb,
    astc_4x4_unorm,
    bc3_srgb,
    bc3_unorm,
    bc5_rg,
    bc6h_ufloat,
    bc6h_sfloat,
    bc7_srgb,
    bc7_unorm,

    undefined, // Must remain last; preceding values are concrete texture formats.
}

TextureFormatInfo :: struct {
    block_extent    : uint32x2,
    bytes_per_block : u32,
    depth           : bool,
    stencil         : bool,
}

@(require_results) get_texture_format_info :: proc(format : Format) -> TextureFormatInfo {
    switch format {
        case .r8_srgb, .r8_unorm, .r8_uint, .s8_uint:
            return {
                block_extent    = {x = 1, y = 1},
                bytes_per_block = 1,
                depth           = false,
                stencil         = format == .s8_uint,
            }
        case .rg8_srgb, .rgba4_unorm, .r5g5b5a1_unorm, .r5g6b5_unorm, .rg8_unorm, .r16_unorm, .rg8_uint, .r16_uint, .r16_float, .d16_unorm:
            return {
                block_extent    = {x = 1, y = 1},
                bytes_per_block = 2,
                depth           = format == .d16_unorm,
                stencil         = false,
            }
        case .rgba8_srgb, .bgra8_srgb, .rgba8_unorm, .bgra8_unorm, .rg16_unorm, .rgba8_uint, .bgra8_uint, .rg16_uint, .r32_uint, .rg16_float, .r32_float, .rgb10a2_unorm, .rg11b10_float, .d24_unorm_s8_uint, .d32_float:
            return {
                block_extent    = {x = 1, y = 1},
                bytes_per_block = 4,
                depth           = format == .d24_unorm_s8_uint || format == .d32_float,
                stencil         = format == .d24_unorm_s8_uint,
            }
        case .rgba16_unorm, .rgba16_uint, .rg32_uint, .rgba16_float, .rg32_float, .d32_float_s8_uint:
            return {
                block_extent    = {x = 1, y = 1},
                bytes_per_block = 8,
                depth           = format == .d32_float_s8_uint,
                stencil         = format == .d32_float_s8_uint,
            }
        case .rgb32_uint, .rgb32_float:
            return {
                block_extent    = {x = 1, y = 1},
                bytes_per_block = 12,
            }
        case .rgba32_uint, .rgba32_float:
            return {
                block_extent    = {x = 1, y = 1},
                bytes_per_block = 16,
            }
        case .eac_rg, .astc_4x4_srgb, .astc_4x4_unorm, .bc3_srgb, .bc3_unorm, .bc5_rg, .bc6h_ufloat, .bc6h_sfloat, .bc7_srgb, .bc7_unorm:
            return {
                block_extent    = {x = 4, y = 4},
                bytes_per_block = 16,
            }
        case .undefined:
            return {}
    }

    return {}
}

TextureType :: enum u8 {
    one_d,
    two_d,
    three_d,
    cube,
    two_d_array,
    cube_array,
}

TextureUsage  :: bit_set[TextureUsages; u32]
TextureUsages :: enum {
    sampled,
    storage,
    color_attachment,
    depth_stencil_attachment,
    transfer_source,
    transfer_destination,
}

TextureDescriptorType :: enum u8 {
    sampled,
    storage,
}

TextureAspect :: enum u8 {
    automatic,
    color,
    depth,
    stencil,
}

Filter :: enum u8 {
    nearest,
    linear,
}

AddressMode :: enum u8 {
    repeat,
    mirrored_repeat,
    clamp_to_edge,
}

CompareOp :: enum u8 {
    never,
    less,
    equal,
    less_equal,
    greater,
    not_equal,
    greater_equal,
    always,
}

CullMode :: enum u8 {
    none,
    clockwise,
    counter_clockwise,
}

BlendFactor :: enum u8 {
    zero,
    one,
    source_color,
    one_minus_source_color,
    destination_color,
    one_minus_destination_color,
    source_alpha,
    one_minus_source_alpha,
    destination_alpha,
    one_minus_destination_alpha,
    source_alpha_saturate,
}

BlendOp :: enum u8 {
    add,
    subtract,
    reverse_subtract,
    minimum,
    maximum,
}

IndexType :: enum u8 {
    uint16,
    uint32,
}

LoadOp :: enum u8 {
    load,
    clear,
    discard,
}

StoreOp :: enum u8 {
    store,
    discard,
}

StencilOp :: enum u8 {
    keep,
    zero,
    replace,
    increment_clamp,
    decrement_clamp,
    invert,
    increment_wrap,
    decrement_wrap,
}

// Ordered by Vulkan's logical execution order where stages are comparable.
// A barrier's before execution scope includes the selected and logically earlier
// stages; its after execution scope includes the selected and logically later
// stages. Vertex and task/mesh are alternative graphics branches, depth_stencil_tests
// spans early and late tests around fragment, compute and transfer are separate
// pipelines, host is a pseudo-stage, and none/all_commands are special masks.
Stage  :: bit_set[Stages; u64]
Stages :: enum {
    indirect,
    index_input,
    vertex,
    task,
    mesh,
    depth_stencil_tests,
    fragment,
    color_output,
    compute,
    transfer,
    host,         // Barrier destination only, paired with host_read.
    all_commands, // All GPU command stages; excludes host.
}

Access   :: bit_set[Accesses; u64]
Accesses :: enum {
    transfer_read,
    transfer_write,
    shader_read,
    shader_write,
    color_read,
    color_write,
    depth_stencil_read,
    depth_stencil_write,
    indirect_read,
    index_read,
    host_read,
    descriptor_read,
}

DeviceCaps :: struct {
    device_name              : cstring,
    max_push_data_size       : u64,
    // Common element size for suballocating TextureHeap storage; every SizeAlign::align divides this value.
    texture_heap_alignment   : u64,
    texture_descriptor_size  : u64, // Bytes per descriptor slot.
    sampler_descriptor_size  : u64, // Bytes per descriptor slot.
    timestamp_period_ns      : f32, // Nanoseconds per timestamp tick.
    sub_texel_precision_bits : u32, // Fractional filtering precision, for conservative sampled-field bounds.
    texture_compression_bc   : bool,
    texture_compression_astc : bool,
    storage_input_output16   : bool,
}

DeviceDesc :: struct {
    window                        : rawptr,
    swapchain_format              : Format,
    desired_swapchain_image_count : u32, // 1..8 presentation contexts.
    timestamp_query_count         : u32, // Per command buffer; zero disables timestamps.
}

DeviceInit :: struct {
    device : ^Device,
    error  : Error,
}

SwapchainFrame :: struct {
    render_view : ^RenderView,
    extent      : uint32x2,
}

TextureDesc :: struct {
    type           : TextureType,
    extent         : uint32x3,
    mip_levels     : u32,
    layer_count    : u32, // Vulkan array layers; cube faces are individual layers.
    format         : Format,
    mutable_format : bool, // Allow format-compatible descriptor views, but could lose DCC.
    usage          : TextureUsage,
}

RenderViewDesc :: struct {
    mip_level : u32,
    slice     : u32, // Physical array slice; cube faces are individual slices.
}

TextureDescriptorDesc :: struct {
    format      : Format, // Undefined inherits the texture format.
    aspect      : TextureAspect, // Automatic selects color, or depth before stencil.
    base_mip    : u32,
    mip_count   : u32, // Zero selects every remaining mip level.
    base_layer  : u32, // Vulkan array layer; cube faces are individual layers.
    layer_count : u32, // Vulkan array layers; zero selects every remaining layer.
}

TextureCopyDesc :: struct {
    mip_level         : u32,
    base_slice        : u32, // Physical array slice; cube faces are individual slices.
    slice_count       : u32, // Zero selects every remaining physical slice.
    offset            : uint32x3,
    extent            : uint32x3, // Zero components select the remaining mip extent.
    row_pitch_bytes   : u64, // Zero is tightly packed.
    slice_pitch_bytes : u64, // Zero is tightly packed.
}

SamplerDesc :: struct {
    min_filter      : Filter,
    mag_filter      : Filter,
    mip_filter      : Filter,
    address_u       : AddressMode,
    address_v       : AddressMode,
    address_w       : AddressMode,
    anisotropic     : bool, // Uses the API's fixed 4x profile.
    compare_enabled : bool,
    compare         : CompareOp,
}

BlendComponentState :: struct {
    source      : BlendFactor,
    destination : BlendFactor,
    operation   : BlendOp,
}

BlendState :: struct {
    enabled : bool,
    color   : BlendComponentState,
    alpha   : BlendComponentState,
}

ColorTargetDesc :: struct {
    format     : Format,
    blend      : BlendState,
    write_mask : u8,
}

RasterizationState :: struct {
    cull                : CullMode,
    depth_bias_constant : f32,
    depth_bias_clamp    : f32,
    depth_bias_slope    : f32,
}

Viewport :: struct {
    x         : f32,
    y         : f32,
    width     : f32,
    height    : f32,
    min_depth : f32,
    max_depth : f32,
}

Scissor :: struct {
    x      : i32,
    y      : i32,
    width  : u32,
    height : u32,
}

StencilFaceState :: struct {
    compare    : CompareOp,
    fail       : StencilOp,
    pass       : StencilOp,
    depth_fail : StencilOp,
    reference  : u8,
}

DepthStencilState :: struct {
    depth_test         : bool,
    depth_write        : bool,
    depth_compare      : CompareOp,
    stencil_test       : bool,
    stencil_read_mask  : u8,
    stencil_write_mask : u8,
    front              : StencilFaceState,
    back               : StencilFaceState,
}

GraphicsPSODesc :: struct {
    vertex_spirv   : []u32,
    fragment_spirv : []u32, // Empty omits the fragment stage, for depth-only rasterization.
    color_targets  : []ColorTargetDesc,
    depth_format   : Format,
    stencil_format : Format,
    rasterization  : RasterizationState,
}

MeshPSODesc :: struct {
    task_spirv     : []u32, // Empty launches mesh workgroups directly; otherwise draws launch taskMain workgroups.
    mesh_spirv     : []u32,
    fragment_spirv : []u32, // Empty omits the fragment stage, for depth-only rasterization.
    color_targets  : []ColorTargetDesc,
    depth_format   : Format,
    stencil_format : Format,
    rasterization  : RasterizationState,
}

ClearColor :: [4]f32

ColorAttachment :: struct {
    render_view : ^RenderView,
    load        : LoadOp,
    store       : StoreOp,
    clear       : ClearColor,
}

DepthAttachment :: struct {
    render_view : ^RenderView,
    load        : LoadOp,
    store       : StoreOp,
    clear       : f32,
}

StencilAttachment :: struct {
    render_view : ^RenderView,
    load        : LoadOp,
    store       : StoreOp,
    clear       : u8,
}

RenderingDesc :: struct {
    colors  : []ColorAttachment,
    depth   : DepthAttachment,
    stencil : StencilAttachment,
}

ByteSpan :: []u8

// A span converted from a value remains valid only while that value is
// alive. Functions must not retain the span.
@(require_results) as_byte_span :: proc(value : ^$T) -> ByteSpan where (size_of(T) & 3) == 0 {
    return (cast([^]u8)value)[:size_of(T)]
}

optimized :: #config(NO_GRAPHICS_API_OPTIMIZED, false)
when optimized {
    foreign import NoGraphicsAPI "../build/RelWithDebInfo/NoGraphicsAPI.lib"
} else {
    foreign import NoGraphicsAPI "../build/Debug/NoGraphicsAPI.lib"
}

@(default_calling_convention = "c", link_prefix="gpu_")
foreign NoGraphicsAPI {
    @(require_results) create_device           :: proc(#by_ptr desc : DeviceDesc) -> DeviceInit ---
                       destroy_device          :: proc(device : ^Device) ---
    @(require_results) get_device_caps         :: proc(device : ^Device) -> ^DeviceCaps ---
    @(require_results) supports_texture_format :: proc(device : ^Device, format : Format, usage : TextureUsage) -> bool ---
    @(require_results) get_drawable_extent     :: proc(device : ^Device) -> uint32x2 ---

    @(require_results) create_timeline_semaphore  :: proc(device : ^Device, initial_value : u64 = 0) -> ^TimelineSemaphore ---
                       destroy_timeline_semaphore :: proc(semaphore : ^TimelineSemaphore) ---
    @(require_results) timeline_completed_value   :: proc(semaphore : ^TimelineSemaphore) -> u64 ---
                       wait_timeline              :: proc(point : TimelinePoint) ---
                       wait_idle                  :: proc(device : ^Device) ---

    @(require_results) acquire            :: proc(device : ^Device) -> SwapchainFrame --- // Empty while the drawable extent is zero.
                       submit_and_present :: proc(device : ^Device, commands : []^CommandBuffer, completion : TimelinePoint) ---

    // Every non-null returned pointer is 16-byte aligned. Descriptor heaps are exact allocations;
    // cpu_visible, gpu_only, and readback heaps are raw blocks for application-side suballocation.
    @(require_results) create_gpu_heap  :: proc(device : ^Device, byte_count : u64, memory : MemoryType = .cpu_visible) -> GpuHeap ---
                       destroy_gpu_heap :: proc(#by_ptr heap : GpuHeap) ---

    // Texture heaps use one device-selected GPU-only memory type and must outlive every placed texture.
    // Placements must satisfy get_texture_size_align(), remain non-overlapping, and not be reused before the timeline point covering their last use completes.
    // DeviceCaps::texture_heap_alignment can be used as a common allocator element size, avoiding per-placement leading alignment padding.
    @(require_results) create_texture_heap      :: proc(device : ^Device, byte_count : u64) -> TextureHeap ---
                       destroy_texture_heap     :: proc(#by_ptr heap : TextureHeap) ---
    @(require_results) get_texture_size_align   :: proc(device : ^Device, #by_ptr desc : TextureDesc) -> SizeAlign ---
    @(require_results) create_texture           :: proc(device : ^Device, #by_ptr desc : TextureDesc, #by_ptr heap : TextureHeap, offset : u64) -> ^Texture ---
                       destroy_texture          :: proc(texture : ^Texture) ---
    @(require_results) create_render_view       :: proc(texture : ^Texture, #by_ptr desc : RenderViewDesc = {}) -> ^RenderView ---
                       destroy_render_view      :: proc(render_view : ^RenderView) ---
                       write_texture_descriptor :: proc(device : ^Device, cpu_destination : rawptr, #by_ptr texture : Texture, type : TextureDescriptorType, #by_ptr desc : TextureDescriptorDesc = {}) ---
                       write_sampler_descriptor :: proc(device : ^Device, cpu_destination : rawptr, #by_ptr desc : SamplerDesc = {}) ---

    @(require_results) create_graphics_pso :: proc(device : ^Device, #by_ptr desc : GraphicsPSODesc) -> ^PSO ---
    @(require_results) create_mesh_pso     :: proc(device : ^Device, #by_ptr desc : MeshPSODesc) -> ^PSO ---
    @(require_results) create_compute_pso  :: proc(device : ^Device, compute_spirv : []u32) -> ^PSO ---
                       destroy_pso         :: proc(pso : ^PSO) ---

    // Create textures before beginning commands. The first begun command buffer initializes them and must be submitted first.
    // Every begun command buffer must be included exactly once in the next submit or submit_and_present call.
    @(require_results) begin_commands :: proc(device : ^Device) -> ^CommandBuffer ---
                       submit         :: proc(commands : []^CommandBuffer, completion : TimelinePoint) ---

    set_texture_descriptor_heap :: proc(commands : ^CommandBuffer, heap : GpuRange) --- // Heap range must be full GpuHeap range
    set_sampler_descriptor_heap :: proc(commands : ^CommandBuffer, heap : GpuRange) --- // Heap range must be full GpuHeap range

    copy_memory            :: proc(commands : ^CommandBuffer, source : GpuRange, destination : GpuRange) ---
    copy_memory_to_texture :: proc(commands : ^CommandBuffer, source : GpuRange, destination : ^Texture, #by_ptr copy : TextureCopyDesc = {}) ---
    copy_texture_to_memory :: proc(commands : ^CommandBuffer, source : ^Texture, destination : ^GpuRange, #by_ptr copy : TextureCopyDesc = {}) ---

    barrier :: proc(commands : ^CommandBuffer, before : Stage, before_access : Access, after : Stage, after_access : Access) ---

    // Up to DeviceDesc::timestamp_query_count markers per command buffer. stage must map to a single GPU pipeline stage.
    // Destinations must be 8-byte aligned and distinct until submission completes.
    // Results are copied at command-buffer end; read mapped readback memory only after submission completes.
    write_timestamp :: proc(commands : ^CommandBuffer, gpu_destination : ^u64, stage : Stage = {.all_commands}) ---

    begin_render_pass :: proc(commands : ^CommandBuffer, #by_ptr desc : RenderingDesc) ---
    end_render_pass   :: proc(commands : ^CommandBuffer) ---

    // begin_render_pass resets a full render-area viewport and scissor and disables depth/stencil; these commands override those defaults until the next pass
    set_viewport      :: proc(commands : ^CommandBuffer, #by_ptr viewport : Viewport) ---
    set_scissor       :: proc(commands : ^CommandBuffer, #by_ptr scissor : Scissor) ---
    set_depth_stencil :: proc(commands : ^CommandBuffer, #by_ptr state : DepthStencilState) ---

    bind_pso :: proc(commands : ^CommandBuffer, pso : ^PSO) ---
    
    // Draw and dispatch root structures must fit 256 bytes. Larger data belongs in GPU memory referenced by root pointers.
    draw                   :: proc(commands : ^CommandBuffer, root : ByteSpan, vertex_count : u32, instance_count : u32 = 1, first_vertex : u32 = 0, first_instance : u32 = 0) ---
    draw_indexed           :: proc(commands : ^CommandBuffer, root : ByteSpan, indices : GpuRange, type : IndexType, index_count : u32, instance_count : u32 = 1, first_index : u32 = 0, vertex_offset : i32 = 0, first_instance : u32 = 0) ---
    draw_indirect          :: proc(commands : ^CommandBuffer, root : ByteSpan, arguments : GpuRange, draw_count : u32 = 1, stride : u32 = 0) ---
    draw_indexed_indirect  :: proc(commands : ^CommandBuffer, root : ByteSpan, indices : GpuRange, type : IndexType, arguments : GpuRange, draw_count : u32 = 1, stride : u32 = 0) ---
    dispatch               :: proc(commands : ^CommandBuffer, root : ByteSpan, group_count : uint32x3) ---
    dispatch_indirect      :: proc(commands : ^CommandBuffer, root : ByteSpan, arguments : GpuRange) ---
    draw_meshlets          :: proc(commands : ^CommandBuffer, root : ByteSpan, group_count : uint32x3) ---
    draw_meshlets_indirect :: proc(commands : ^CommandBuffer, root : ByteSpan, arguments : GpuRange, draw_count : u32 = 1, stride : u32 = 0) ---
}
