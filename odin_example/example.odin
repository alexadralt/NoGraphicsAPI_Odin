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

    frames_in_filght :: 2
    device_init := gpu.create_device({
        window                        = window,
        swapchain_format              = .bgra8_srgb,
        desired_swapchain_image_count = frames_in_filght,
        desired_queue_count           = 1,
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

    cmd_pools : [frames_in_filght]^gpu.CommandPool
    for &pool in cmd_pools do pool = gpu.create_command_pool(device)
    defer for pool in cmd_pools do gpu.destroy_command_pool(pool)

    for pump_example_window(window) {
        if latest_completion.value >= 2 do gpu.wait_timeline({semaphore = latest_completion.semaphore, value = latest_completion.value - 1})

        cmd_pool := cmd_pools[latest_completion.value % frames_in_filght]
        gpu.reset_command_pool(cmd_pool)
        commands := gpu.begin_commands(cmd_pool)
        frame := gpu.acquire(commands)
        if frame.render_view == nil do continue

        gpu.begin_render_pass(commands, {
            colors = { { render_view = frame.render_view, load = .clear } },
        })
        
        gpu.bind_pso(commands, triangle_pso)
        gpu.draw(commands, nil, 3)
        gpu.end_render_pass(commands)
        
        gpu.end_commands(commands)
        latest_completion.value += 1
        gpu.submit_and_present(device, { commands = {commands}, completion = latest_completion })
    }

    gpu.wait_idle(device)
}
