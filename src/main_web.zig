const std = @import("std");
const wasm = @import("web/wasm.zig");
const keys = @import("web/keys.zig");
const canvas = @import("web/canvas.zig");
const gfx = @import("gfx.zig");

const Game = @import("game.zig");

var gpa: std.heap.GeneralPurposeAllocator(.{}) = undefined;
var allocator: *std.mem.Allocator = undefined;
var game: Game = undefined;

export fn onInit() void {
    gpa = std.heap.GeneralPurposeAllocator(.{}){};
    allocator = &gpa.allocator;
    canvas.fontFamily("PressStart2P");
    game = Game.init(allocator) catch unreachable;
    //game.state = .play;
}

export fn onResize(w: c_uint, h: c_uint) void {
    game.setSize(@intToFloat(f32, w), @intToFloat(f32, h));
}

export fn onKeyDown(key: c_uint) void {
    var text: [1]u8 = undefined;
    switch (key) {
        keys.KEY_ENTER => game.onKeyReturn(),
        keys.KEY_BACKSPACE => game.onKeyBackspace(),
        keys.KEY_0...keys.KEY_9 => {
            text[0] = '0' + @intCast(u8, key - keys.KEY_0);
            game.onTextInput(&text) catch unreachable;
        },
        keys.KEY_A...keys.KEY_Z => {
            text[0] = @intCast(u8, key);
            game.onTextInput(&text) catch unreachable;
        },
        keys.KEY_SPACE => game.onTextInput(" ") catch unreachable,
        else => {},
    }
}

export fn onAnimationFrame() void {
    game.tick();

    canvas.fillColor(canvas.rgbf(0.3, 0.5, 0.8));
    canvas.rect(0, 0, game.width, game.height);
    canvas.fill();
    game.draw();
}