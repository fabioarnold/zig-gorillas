const std = @import("std");
const builtin = @import("builtin");
const mem = std.mem;
const Allocator = mem.Allocator;

const c = @import("c.zig");
const nvg = @import("nvg.zig");

const Game = @import("game.zig");

extern fn gladLoadGL() callconv(.C) c_int; // init OpenGL function pointers on Windows and Linux
extern fn SetProcessDPIAware() callconv(.C) c_int;

var sdl_window: ?*c.SDL_Window = null;
var sdl_gl_context: c.SDL_GLContext = undefined;

var video_width: f32 = 1280;
var video_height: f32 = 720;
var video_scale: f32 = 1;
var fullscreen: bool = false;

var game: Game = undefined;

fn draw() void {
    sdlSetupFrame();

    c.glClearColor(0.3, 0.5, 0.8, 1);
    c.glClear(c.GL_COLOR_BUFFER_BIT);

    nvg.beginFrame(video_width, video_height, video_scale);
    game.draw();
    nvg.endFrame();

    //c.glFlush();
    c.SDL_GL_SwapWindow(sdl_window);
}

var first_surrogate_half: ?u16 = null;

fn sdlProcessTextInput(text_event: c.SDL_TextInputEvent) !void {
    const text = mem.sliceTo(std.meta.assumeSentinel(&text_event.text, 0), 0);

    if (std.unicode.utf8ValidateSlice(text)) {
        try game.onTextInput(text);
    } else if (text.len == 3) { // Windows specific?
        _ = std.unicode.utf8Decode(text) catch |err| switch (err) {
            error.Utf8EncodesSurrogateHalf => {
                var codepoint: u21 = text[0] & 0b00001111;
                codepoint <<= 6;
                codepoint |= text[1] & 0b00111111;
                codepoint <<= 6;
                codepoint |= text[2] & 0b00111111;
                const surrogate = @intCast(u16, codepoint);

                if (first_surrogate_half) |first_surrogate0| {
                    const utf16 = [_]u16{ first_surrogate0, surrogate };
                    var utf8 = [_]u8{0} ** 4;
                    _ = std.unicode.utf16leToUtf8(&utf8, &utf16) catch unreachable;
                    first_surrogate_half = null;

                    try game.onTextInput(&utf8);
                } else {
                    first_surrogate_half = surrogate;
                }
            },
            else => {},
        };
    }
}

fn getVideoScale() f32 {
    const default_dpi: f32 = switch (builtin.os.tag) {
        .windows => 96,
        .macos => 72,
        else => 96, // TODO
    };
    const display = if (sdl_window) |_| c.SDL_GetWindowDisplayIndex(sdl_window) else 0;
    var dpi: f32 = undefined;
    _ = c.SDL_GetDisplayDPI(display, &dpi, null, null);
    return dpi / default_dpi;
}

fn sdlSetupFrame() void {
    const new_video_scale = getVideoScale();
    if (new_video_scale != video_scale) { // DPI change
        //std.debug.print("new_video_scale {} {}\n", .{ new_video_scale, dpi });
        video_scale = new_video_scale;
        var window_width: i32 = undefined;
        var window_height: i32 = undefined;
        if (builtin.os.tag == .macos) {
            window_width = @floatToInt(i32, video_width);
            window_height = @floatToInt(i32, video_height);
        } else {
            window_width = @floatToInt(i32, video_scale * video_width);
            window_height = @floatToInt(i32, video_scale * video_height);
        }
        c.SDL_SetWindowSize(sdl_window, window_width, window_height);
    }

    var drawable_width: i32 = undefined;
    var drawable_height: i32 = undefined;
    c.SDL_GL_GetDrawableSize(sdl_window, &drawable_width, &drawable_height);
    c.glViewport(0, 0, drawable_width, drawable_height);

    // only when window is resizable
    video_width = @intToFloat(f32, drawable_width) / video_scale;
    video_height = @intToFloat(f32, drawable_height) / video_scale;
    game.setSize(video_width, video_height);
}

fn sdlToggleFullscreen() void {
    fullscreen = !fullscreen;
    _ = c.SDL_SetWindowFullscreen(sdl_window, if (fullscreen) c.SDL_WINDOW_FULLSCREEN_DESKTOP else 0);
    _ = c.SDL_ShowCursor(if (fullscreen) c.SDL_DISABLE else c.SDL_ENABLE);
}

fn sdlEventWatch(userdata: ?*anyopaque, sdl_event_ptr: [*c]c.SDL_Event) callconv(.C) c_int {
    _ = userdata;
    const sdl_event = sdl_event_ptr[0];
    if (sdl_event.type == c.SDL_WINDOWEVENT and sdl_event.window.event == c.SDL_WINDOWEVENT_RESIZED) {
        draw();
        return 0;
    }
    return 1; // unhandled
}

pub fn main() !void {
    if (builtin.os.tag == .windows) {
        _ = SetProcessDPIAware();
    }
    if (c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_TIMER) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    _ = c.SDL_GL_SetAttribute(c.SDL_GL_STENCIL_SIZE, 1);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_MULTISAMPLEBUFFERS, 1);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_MULTISAMPLESAMPLES, 4);
    const window_flags = c.SDL_WINDOW_OPENGL | c.SDL_WINDOW_ALLOW_HIGHDPI | c.SDL_WINDOW_RESIZABLE;
    var window_width: i32 = undefined;
    var window_height: i32 = undefined;
    video_scale = getVideoScale();
    if (builtin.os.tag == .macos) {
        window_width = @floatToInt(i32, video_width);
        window_height = @floatToInt(i32, video_height);
    } else {
        window_width = @floatToInt(i32, video_scale * video_width);
        window_height = @floatToInt(i32, video_scale * video_height);
    }
    sdl_window = c.SDL_CreateWindow("Zig Gorillas", c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED, window_width, window_height, window_flags);
    if (sdl_window == null) {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLCreateWindowFailed;
    }
    defer c.SDL_DestroyWindow(sdl_window);

    sdl_gl_context = c.SDL_GL_CreateContext(sdl_window);
    if (sdl_gl_context == null) {
        c.SDL_Log("Unable to create gl context: %s", c.SDL_GetError());
        return error.SDLCreateGLContextFailed;
    }
    defer c.SDL_GL_DeleteContext(sdl_gl_context);

    _ = c.SDL_GL_SetSwapInterval(1);

    if (builtin.os.tag == .windows or builtin.os.tag == .linux) {
        _ = gladLoadGL();
    }

    c.SDL_AddEventWatch(sdlEventWatch, null);

    nvg.init();
    defer nvg.quit();

    _ = nvg.createFontMem("font", @embedFile("../art/PressStart2P-Regular.ttf"));

    var gpa = std.heap.GeneralPurposeAllocator(.{
        .enable_memory_limit = true,
    }){};
    defer {
        const leaked = gpa.deinit();
        if (leaked) @panic("Memory leak :(");
    }

    game = try Game.init(gpa.allocator());
    defer game.deinit();

    mainLoop: while (true) {
        var sdl_event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&sdl_event) != 0) {
            switch (sdl_event.type) {
                c.SDL_QUIT => break :mainLoop,
                c.SDL_TEXTINPUT => try sdlProcessTextInput(sdl_event.text),
                c.SDL_KEYDOWN => switch (sdl_event.key.keysym.sym) {
                    c.SDLK_RETURN, c.SDLK_KP_ENTER => game.onKeyReturn(),
                    c.SDLK_BACKSPACE => game.onKeyBackspace(),
                    c.SDLK_F11 => sdlToggleFullscreen(),
                    else => {},
                },
                else => {},
            }
        }

        game.tick();
        draw();
    }
}
