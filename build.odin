package build

import "core:os"
import "core:fmt"
import "core:slice"
import "core:strings"
import "base:runtime"

import stbtt "vendor:stb/truetype"

output_directory :: "out"

optimized_build : bool

main :: proc() {
    fmt.println("running build metaprogram")

    output_path, _ := os.get_absolute_path(output_directory, context.temp_allocator)
    if !os.exists(output_path) {
        os.make_directory(output_path)
    }

    optimized_build = slice.contains(os.args, "optimized_build")

    // run cmake to build the main library
    cmake_build_path, _ := os.get_absolute_path("build", context.temp_allocator)
    if !os.exists(cmake_build_path) {
        process_desc := os.Process_Desc{
            command = []string{"cmake", "-S", ".", "-B", "build"}
        }

        state, stdout, stderr, err := os.process_exec(process_desc, context.temp_allocator)
        if err != os.ERROR_NONE {
            fmt.printfln("could not run cmake: %v", err)
            return
        }

        if len(stdout) != 0 do fmt.printf("%v\n\n", string(stdout))
        if len(stderr) != 0 do fmt.printf("%v\n\n", string(stderr))
        fmt.printf("cmake build files generation finished with code %v\n\n", state.exit_code)

        if state.exit_code != 0 || len(stderr) != 0 do return
    }

    cmake_args : [dynamic]string
    cmake_args.allocator = context.temp_allocator
    append(&cmake_args, "cmake", "--build", "build")

    if optimized_build {
        append(&cmake_args, "--config", "RelWithDebInfo")
    } else {
        append(&cmake_args, "--config", "Debug")
    }

    cmake_process_desc := os.Process_Desc{
        command = cmake_args[:]
    }
    state, stdout, stderr, err := os.process_exec(cmake_process_desc, context.temp_allocator)
    if err != os.ERROR_NONE {
        fmt.printfln("could not run cmake: %v", err)
        return
    }

    if len(stdout) != 0 do fmt.printf("%v\n\n", string(stdout))
    if len(stderr) != 0 do fmt.printf("%v\n\n", string(stderr))
    fmt.printf("main library compilation finished with code %v\n\n", state.exit_code)

    if state.exit_code != 0 || len(stderr) != 0 do return

    // generate compiler flags

    args : [dynamic]string
    args.allocator = context.temp_allocator
    append(&args, "odin", "build", "odin_example")

    exe_name := "example"
    if optimized_build {
        exe_name = fmt.tprintf("%v_optimized", exe_name)
    }

    append(&args, fmt.tprintf("-out:%v/%v.exe", output_directory, exe_name))
    append(&args, "-debug") // tell the compiler to generate pdb; also forces ODIN_DEBUG to be true which is unfortunate

    // default optimization level is -o:minimal
    if optimized_build {
        append(&args, "-o:speed")
    }

    append(&args, fmt.tprintf("-define:NO_GRAPHICS_API_OPTIMIZED=%v", optimized_build))

    vulkan_sdk_path := os.get_env_alloc("VULKAN_SDK", context.temp_allocator)
    if len(vulkan_sdk_path) == 0 {
        fmt.printfln("failed to fetch vulkan sdk path from environment variable")
        return
    }
    vulkan_loader_path, _ := os.join_path([]string{vulkan_sdk_path, "Lib", "vulkan-1.lib"}, context.temp_allocator)

    when ODIN_OS == .Windows {
        append(&args, fmt.tprintf("-extra-linker-flags:%v", vulkan_loader_path))
    } else {
        #panic("linker flags are not specified for this paltform")
    }

    // compiling assets
    assets_directory, _ := os.join_path([]string{"odin_example", "assets"}, context.temp_allocator)

    assets_path, _ := os.get_absolute_path(assets_directory, context.temp_allocator)
    if !os.exists(assets_path) {
        fmt.printfln("could not find assets directory at %v", assets_path)
        return
    }

    // compiling shaders

    shaders_dir_path, _ := os.join_path([]string{assets_path, "shaders"}, context.temp_allocator)
    if !os.exists(shaders_dir_path) {
        fmt.printfln("could not find assets/shaders directory at %v", shaders_dir_path)
        return
    }

    shader_binary_dir_path, _ := os.join_path([]string{shaders_dir_path, "compiled"}, context.temp_allocator)
    if !os.exists(shader_binary_dir_path) {
        os.make_directory(shader_binary_dir_path)
    }

    if !compile_shader(&args, shaders_dir_path, "example_triangle", .vertex)   do return
    if !compile_shader(&args, shaders_dir_path, "example_triangle", .fragment) do return

    // running the compiler

    process_desc := os.Process_Desc{
        command = args[:]
    }
    state, stdout, stderr, err = os.process_exec(process_desc, context.temp_allocator)
    if err != os.ERROR_NONE {
        fmt.printfln("could not run the compiler: %v", err)
        return
    }

    if len(stdout) != 0 do fmt.printf("%v\n\n", string(stdout))
    if len(stderr) != 0 do fmt.printf("%v\n\n", string(stderr))
    fmt.printf("odin example compilation finished with code %v\n\n", state.exit_code)
}

Shader_Type :: enum {
    vertex,
    fragment,
    compute,
}

compile_shader :: proc(args : ^[dynamic]string, shaders_dir_path : string, shader : string, type : Shader_Type) -> (ok : bool) {
    defer if !ok do fmt.printfln("failed to compile shader %v", shader)

    shader_file_extension :: "slang"
    
    shader_path, _ := os.join_path([]string{shaders_dir_path, fmt.tprintf("%v.%v", shader, shader_file_extension)}, context.temp_allocator)
    if !os.exists(shader_path) {
        fmt.printfln("could not find shader %v", shader_path)
        return false
    }

    shader_binary_path, _ := os.join_path([]string{shaders_dir_path, "compiled", fmt.tprintf("%v_%v", shader, type)}, context.temp_allocator)
    compile_slang_shader(shader_path, shader_binary_path, type) or_return

    append(args, fmt.tprintf("-define:SHADER_%v_%v_BINARY_PATH=%v", shader, type, shader_binary_path))
    return true
}

compile_slang_shader :: proc(shader_path : string, shader_binary_path : string, type : Shader_Type) -> (ok : bool) {
    fmt.printfln("compiling %v shader %v", type, shader_path)

    process_desc := os.Process_Desc{
        command = []string{
            "slangc", shader_path,
            "-target", "spirv",
            "-profile", "spirv_1_5",
            "-emit-spirv-directly",
            "-fvk-use-entrypoint-name",
            "-fvk-use-c-layout",
            "-matrix-layout-row-major",
            "-capability", "spvDescriptorHeapEXT",
            "-entry", fmt.tprintf("%vMain", type),
            "-stage", fmt.tprintf("%v", type),
            "-o", shader_binary_path,
        }
    }
    state, stdout, stderr, err := os.process_exec(process_desc, context.temp_allocator)
    if err != os.ERROR_NONE {
        fmt.printfln("could not run the slang compiler: %v", err)
        return
    }

    if len(stdout) != 0 do fmt.printf("%v\n\n", string(stdout))
    if len(stderr) != 0 do fmt.printf("%v\n\n", string(stderr))
    if state.exit_code != 0 do fmt.printf("compilation finished with code %v\n\n", state.exit_code)

    return state.exit_code == 0 && len(stderr) == 0 && len(stdout) == 0 && validate_spirv(shader_binary_path)
}

validate_spirv :: proc(path : string) -> (ok : bool) {
    process_desc := os.Process_Desc{
        command = []string{
            "spirv-val",
            "--target-env", "vulkan1.4",
            "--scalar-block-layout",
            path,
        }
    }
    state, stdout, stderr, err := os.process_exec(process_desc, context.temp_allocator)
    if err != os.ERROR_NONE {
        fmt.printfln("could not run spirv-val: %v", err)
        return
    }

    if len(stdout) != 0 do fmt.printf("%v\n\n", string(stdout))
    if len(stderr) != 0 do fmt.printf("%v\n\n", string(stderr))
    if state.exit_code != 0 do fmt.printf("spirv validation finished with code: %v\n\n", state.exit_code)

    return state.exit_code == 0 && len(stderr) == 0 && len(stdout) == 0
}
