package odin_example

import gpu "../odin"

import "core:fmt"

vertex_shader   := #load(#config(SHADER_example_triangle_vertex_BINARY_PATH,   ""), []u32)
fragment_shader := #load(#config(SHADER_example_triangle_fragment_BINARY_PATH, ""), []u32)

main :: proc() {
    width  :: 512
    height :: 512
    window := open_example_window("NoGraphicsAPI triangle", width, height)
    if window == nil {
        fmt.printfln("failed to open window")
        return
    }
    defer close_example_window(window)

    device_init := gpu.create_device({
        window                        = window,
        swapchain_format              = .bgra8_srgb,
        desired_swapchain_image_count = 2,
    })
    if device_init.error != .none {
        fmt.printfln("Error when creating device: %v", device_init.error)
        return
    }
    device := device_init.device
    defer gpu.destroy_device(device)

    device_caps := gpu.get_device_caps(device)
    fmt.printfln("Using device: %v", device_caps.device_name)

    triangle_pso := gpu.create_graphics_pso(device, {
        vertex_spirv   = vertex_shader,
        fragment_spirv = fragment_shader,
        color_targets  = {
            {format = .bgra8_srgb, write_mask = 0xf},
        },
        depth_format   = .undefined,
        stencil_format = .undefined,
    })
    defer gpu.destroy_pso(triangle_pso)

    latest_completion := gpu.TimelinePoint{ semaphore = gpu.create_timeline_semaphore(device) }
    defer gpu.destroy_timeline_semaphore(latest_completion.semaphore)

    for pump_example_window(window) {
        frame := gpu.acquire(device)
        if frame.render_view == nil do continue
        
        commands := gpu.begin_commands(device)
        gpu.begin_render_pass(commands, {
            colors = { { render_view = frame.render_view, load = .clear } },
        })
        
        gpu.bind_pso(commands, triangle_pso)
        gpu.draw(commands, nil, 3)
        gpu.end_render_pass(commands)
        
        latest_completion.value += 1
        gpu.submit_and_present(device, { commands }, latest_completion)
    }

    gpu.wait_idle(device)
}
