#include "../include/NoGraphicsAPI/NoGraphicsAPI.hpp"

extern "C" {
    gpu::DeviceInit gpu_create_device(const gpu::DeviceDesc* desc) {
        return gpu::create_device(*desc);
    }
    
    void gpu_destroy_device(gpu::Device* device) {
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



    gpu::TimelineSemaphore* gpu_create_timeline_semaphore(gpu::Device* device, uint64 initial_value) {
        return gpu::create_timeline_semaphore(device, initial_value);
    }

    void gpu_destroy_timeline_semaphore(gpu::TimelineSemaphore* semaphore) {
        return gpu::destroy_timeline_semaphore(semaphore);
    }

    uint64 gpu_timeline_completed_value(const gpu::TimelineSemaphore* semaphore) {
        return gpu::timeline_completed_value(semaphore);
    }

    void gpu_wait_timeline(gpu::TimelinePoint point) {
        return gpu::wait_timeline(point);
    }

    void gpu_wait_idle(gpu::Device* device) {
        return gpu::wait_idle(device);
    }



    gpu::SwapchainFrame gpu_acquire(gpu::Device* device) {
        return gpu::acquire(device);
    }

    void gpu_submit_and_present(gpu::Device* device, gpu::Span<gpu::CommandBuffer* const> commands, gpu::TimelinePoint completion) {
        return gpu::submit_and_present(device, commands, completion);
    }

    

    gpu::GpuHeap gpu_create_gpu_heap(gpu::Device* device, uint64 byte_count, gpu::MemoryType memory) {
        return gpu::create_gpu_heap(device, byte_count, memory);
    }

    void gpu_destroy_gpu_heap(const gpu::GpuHeap* heap) {
        return gpu::destroy_gpu_heap(*heap);
    }



    gpu::TextureHeap gpu_create_texture_heap(gpu::Device* device, uint64 byte_count) {
        return gpu::create_texture_heap(device, byte_count);
    }

    void gpu_destroy_texture_heap(const gpu::TextureHeap* heap) {
        return gpu::destroy_texture_heap(*heap);
    }

    gpu::SizeAlign gpu_get_texture_size_align(gpu::Device* device, const gpu::TextureDesc* desc) {
        return gpu::get_texture_size_align(device, *desc);
    }

    gpu::Texture* gpu_create_texture(gpu::Device* device, const gpu::TextureDesc* desc, const gpu::TextureHeap* heap, uint64 offset) {
        return gpu::create_texture(device, *desc, *heap, offset);
    }

    void gpu_destroy_texture(gpu::Texture* texture) {
        return gpu::destroy_texture(texture);
    }

    gpu::RenderView* gpu_create_render_view(gpu::Texture* texture, const gpu::RenderViewDesc* desc) {
        return gpu::create_render_view(texture, *desc);
    }

    void gpu_destroy_render_view(gpu::RenderView* render_view) {
        return gpu::destroy_render_view(render_view);
    }

    void gpu_write_texture_descriptor(gpu::Device* device, void* cpu_destination, const gpu::Texture* texture,
                                  gpu::TextureDescriptorType type, const gpu::TextureDescriptorDesc* desc) {
        return gpu::write_texture_descriptor(device, cpu_destination, texture, type, *desc);
    }

    void gpu_write_sampler_descriptor(gpu::Device* device, void* cpu_destination, const gpu::SamplerDesc* desc) {
        return gpu::write_sampler_descriptor(device, cpu_destination, *desc);
    }

    

    gpu::PSO* gpu_create_graphics_pso(gpu::Device* device, const gpu::GraphicsPSODesc* desc) {
        return gpu::create_graphics_pso(device, *desc);
    }

    gpu::PSO* gpu_create_mesh_pso(gpu::Device* device, const gpu::MeshPSODesc* desc) {
        return gpu::create_mesh_pso(device, *desc);
    }

    gpu::PSO* gpu_create_compute_pso(gpu::Device* device, gpu::Span<const uint32> compute_spirv) {
        return gpu::create_compute_pso(device, compute_spirv);
    }

    void gpu_destroy_pso(gpu::PSO* pso) {
        return gpu::destroy_pso(pso);
    }



    gpu::CommandBuffer* gpu_begin_commands(gpu::Device* device) {
        return gpu::begin_commands(device);
    }

    void gpu_submit(gpu::Span<gpu::CommandBuffer* const> commands, gpu::TimelinePoint completion) {
        return gpu::submit(commands, completion);
    }



    void gpu_set_texture_descriptor_heap(gpu::CommandBuffer* commands, gpu::GpuRange heap) {
        return gpu::set_texture_descriptor_heap(commands, heap);
    }

    void gpu_set_sampler_descriptor_heap(gpu::CommandBuffer* commands, gpu::GpuRange heap) {
        return gpu::set_sampler_descriptor_heap(commands, heap);
    }

    

    void gpu_copy_memory(gpu::CommandBuffer* commands, gpu::GpuRange source, gpu::GpuRange destination) {
        return gpu::copy_memory(commands, source, destination);
    }

    void gpu_copy_memory_to_texture(gpu::CommandBuffer* commands, gpu::GpuRange source, gpu::Texture* destination, const gpu::TextureCopyDesc* copy) {
        return gpu::copy_memory_to_texture(commands, source, destination, *copy);
    }

    void gpu_copy_texture_to_memory(gpu::CommandBuffer* commands, gpu::Texture* source, gpu::GpuRange destination, const gpu::TextureCopyDesc* copy) {
        return gpu::copy_texture_to_memory(commands, source, destination, *copy);
    }



    void gpu_barrier(gpu::CommandBuffer* commands, gpu::Stage before, gpu::Access before_access, gpu::Stage after, gpu::Access after_access) {
        return gpu::barrier(commands, before, before_access, after, after_access);
    }



    void gpu_write_timestamp(gpu::CommandBuffer* commands, uint64* gpu_destination, gpu::Stage stage) {
        return gpu::write_timestamp(commands, gpu_destination, stage);
    }



    void gpu_begin_render_pass(gpu::CommandBuffer* commands, const gpu::RenderingDesc* desc) {
        return gpu::begin_render_pass(commands, *desc);
    }

    void gpu_end_render_pass(gpu::CommandBuffer* commands) {
        return gpu::end_render_pass(commands);
    }



    void gpu_set_viewport(gpu::CommandBuffer* commands, const gpu::Viewport* viewport) {
        return gpu::set_viewport(commands, *viewport);
    }

    void gpu_set_scissor(gpu::CommandBuffer* commands, const gpu::Scissor* scissor) {
        return gpu::set_scissor(commands, *scissor);
    }

    void gpu_set_depth_stencil(gpu::CommandBuffer* commands, const gpu::DepthStencilState* state) {
        return gpu::set_depth_stencil(commands, *state);
    }



    void gpu_bind_pso(gpu::CommandBuffer* commands, const gpu::PSO* pso) {
        return gpu::bind_pso(commands, pso);
    }



    void gpu_draw(gpu::CommandBuffer* commands, gpu::ByteSpan root, uint32 vertex_count, uint32 instance_count, uint32 first_vertex, uint32 first_instance) {
        return gpu::draw(commands, root, vertex_count, instance_count, first_vertex, first_instance);
    }

    void gpu_draw_indexed(gpu::CommandBuffer* commands, gpu::ByteSpan root, gpu::GpuRange indices, gpu::IndexType type, uint32 index_count, uint32 instance_count,
                          uint32 first_index, int32 vertex_offset, uint32 first_instance) {
        return gpu::draw_indexed(commands, root, indices, type, index_count, instance_count, first_index, vertex_offset, first_instance);
    }

    void gpu_draw_indirect(gpu::CommandBuffer* commands, gpu::ByteSpan root, gpu::GpuRange arguments, uint32 draw_count, uint32 stride) {
        return gpu::draw_indirect(commands, root, arguments, draw_count, stride);
    }

    void gpu_draw_indexed_indirect(gpu::CommandBuffer* commands, gpu::ByteSpan root, gpu::GpuRange indices, gpu::IndexType type, gpu::GpuRange arguments,
                                uint32 draw_count, uint32 stride) {
        return gpu::draw_indexed_indirect(commands, root, indices, type, arguments, draw_count, stride);
    }



    void gpu_dispatch(gpu::CommandBuffer* commands, gpu::ByteSpan root, gpu::uint32x3 group_count) {
        return gpu::dispatch(commands, root, group_count);
    }

    void gpu_dispatch_indirect(gpu::CommandBuffer* commands, gpu::ByteSpan root, gpu::GpuRange arguments) {
        return gpu::dispatch_indirect(commands, root, arguments);
    }

    void gpu_draw_meshlets(gpu::CommandBuffer* commands, gpu::ByteSpan root, gpu::uint32x3 group_count) {
        return gpu::draw_meshlets(commands, root, group_count);
    }

    void gpu_draw_meshlets_indirect(gpu::CommandBuffer* commands, gpu::ByteSpan root, gpu::GpuRange arguments, uint32 draw_count, uint32 stride) {
        return gpu::draw_meshlets_indirect(commands, root, arguments, draw_count, stride);
    }
}
