package odin_test

import gpu "../odin"

import "core:fmt"

FRAMES_IN_FLIGHT :: 2

main :: proc() {
    device_init := gpu.create_device({
        swapchain_format = .bgra8_unorm,
        desired_swapchain_image_count = FRAMES_IN_FLIGHT,
    })
    if device_init.error != .none {
        fmt.printfln("Error when creating device: %v", device_init.error)
        return
    }
    device := device_init.device

    device_caps := gpu.get_device_caps(device)
    fmt.printfln("Using device: %v", device_caps.device_name)
    gpu.destroy_device(device)
}
