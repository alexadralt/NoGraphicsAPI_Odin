package odin_example

import win32 "core:sys/windows"

window_class_name :: "NoGraphicsAPI_example_window";
window_style :: win32.WS_OVERLAPPEDWINDOW;

example_window_proc :: proc "system" (hwnd : win32.HWND, message : win32.UINT, wparam : win32.WPARAM, lparam : win32.LPARAM) -> win32.LRESULT {
    switch message {
        case win32.WM_ERASEBKGND:
            return 1
        case win32.WM_CLOSE:
            win32.ShowWindow(hwnd, win32.SW_HIDE)
            win32.PostQuitMessage(0)
            return 0;
        case win32.WM_KEYDOWN:
            if wparam == win32.VK_ESCAPE {
                win32.ShowWindow(hwnd, win32.SW_HIDE)
                win32.PostQuitMessage(0)
                return 0
            }
            return win32.DefWindowProcW(hwnd, message, wparam, lparam)
        case win32.WM_DESTROY:
            win32.PostQuitMessage(0)
            return 0
    }

    return win32.DefWindowProcW(hwnd, message, wparam, lparam);
}

open_example_window :: proc(title : cstring16, width : u32, height : u32) -> rawptr {
    assert(len(title) != 0 && width != 0 && height != 0)
    
    instance := win32.GetModuleHandleW(nil)
    window_class := win32.WNDCLASSEXW{
        cbSize        = size_of(win32.WNDCLASSEXA),
        style         = win32.CS_HREDRAW | win32.CS_VREDRAW | win32.CS_OWNDC,
        lpfnWndProc   = example_window_proc,
        hInstance     = cast(win32.HANDLE) instance,
        hCursor       = win32.LoadCursorA(nil, win32.IDC_ARROW),
        lpszClassName = window_class_name,
    }
    if win32.RegisterClassExW(&window_class) == 0 do return nil

    rectangle := win32.RECT{
        right = cast(win32.LONG) width,
        bottom = cast(win32.LONG) height,
    }
    if !win32.AdjustWindowRectEx(&rectangle, window_style, false, 0) do return nil

    hwnd := win32.CreateWindowExW(
        0,
        window_class_name,
        title,
        window_style,
        win32.CW_USEDEFAULT,
        win32.CW_USEDEFAULT,
        rectangle.right - rectangle.left,
        rectangle.bottom - rectangle.top,
        nil,
        nil,
        cast(win32.HANDLE) instance,
        nil)
    if hwnd == nil do return nil
    win32.ShowWindow(hwnd, win32.SW_SHOWDEFAULT)
    win32.UpdateWindow(hwnd)
    return hwnd
}

pump_example_window :: proc(window : rawptr) -> bool {
    for {
        message : win32.MSG
        for win32.PeekMessageW(&message, nil, 0, 0, win32.PM_REMOVE) {
            if message.message == win32.WM_QUIT do return false
            win32.TranslateMessage(&message)
            win32.DispatchMessageW(&message)
        }

        if !win32.IsIconic(cast(win32.HWND) window) do return true
        win32.WaitMessage()
    }
}

close_example_window :: proc(window : rawptr) {
    if window != nil do win32.DestroyWindow(cast(win32.HWND) window)
}
