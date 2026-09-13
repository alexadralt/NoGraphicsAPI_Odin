foreign import NoGraphicsAPI "../build/Debug/NoGraphicsAPI.lib"

Device :: struct {}

Error :: enum u8 {
    none = 0,
    unsupported,
    device_lost,
    driver_error,
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

@(default_calling_convention ="C", link_prefix="_gpu")
foreign NoGraphicsAPI {
    @(require_results) create_device :: proc(desc : ^DeviceDesc) -> DeviceInit ---
    gpu_desctroy_device :: proc(device : ^Device) ---
}
