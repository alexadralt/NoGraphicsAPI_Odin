#include "../include/NoGraphicsAPI/NoGraphicsAPI.hpp"

extern "C" {
    gpu::DeviceInit gpu_create_device(const gpu::DeviceDesc* desc) {
        return gpu::create_device(*desc);
    }
    
    void gpu_desctroy_device(gpu::Device* device) {
        return gpu::destroy_device(device);
    }

    const gpu::DeviceCaps* gpu_get_device_caps(const gpu::Device* device) {
        return &gpu::get_device_caps(device);
    }

    bool gpu_supports_texture_format(const gpu::Device* device, gpu::Format format, gpu::TextureUsage usage) {
        return gpu::supports_texture_format(device, format, usage);
    }

    gpu::uint32x2 gpu_get_drawable_extent(gpu::Device* device) {
        return gpu::get_drawable_extent(device);
    }
}
