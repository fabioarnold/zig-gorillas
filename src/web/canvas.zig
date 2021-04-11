const std = @import("std");
const js = @import("canvasjs.zig");

pub const Color = struct { r: u8, g: u8, b: u8, a: u8 };

pub const Paint = struct {};

pub const LineCap = enum(u2) {
    butt,
    round,
    square,
};

pub const LineJoin = enum(u2) {
    miter,
    round,
    bevel,
};

pub const TextAlign = enum(u8) {
    left,
    center,
    right,
};

pub const TextBaseline = enum(u8) {
    alphabetic,
    top,
    hanging,
    middle,
    ideographic,
    bottom,
};

pub fn rgb(r: u8, g: u8, b: u8) Color {
    return .{ .r = r, .g = g, .b = b, .a = 0xff };
}

pub fn rgbf(r: f32, g: f32, b: f32) Color {
    return .{
        .r = @floatToInt(u8, r * 255.0),
        .g = @floatToInt(u8, g * 255.0),
        .b = @floatToInt(u8, b * 255.0),
        .a = 0xff,
    };
}

pub fn linearGradient(sx: f32, sy: f32, ex: f32, ey: f32, icol: Color, ocol: Color) Paint {
    return .{}; // TODO
}

pub const save = js.save;
pub const restore = js.restore;
pub const translate = js.translate;
pub const rotate = js.rotate;
pub const scale = js.scale;
pub fn scissor(x: f32, y: f32, w: f32, h: f32) void {
    save();
    beginPath();
    rect(x, y, w, h);
    js.clip();
}
pub fn resetScissor() void {
    restore();
}
pub const beginPath = js.beginPath;
pub const closePath = js.closePath;
pub const rect = js.rect;
pub fn circle(x: f32, y: f32, r: f32) void {
    js.arc(x, y, r, 0, 2 * std.math.pi);
}
pub const moveTo = js.moveTo;
pub const lineTo = js.lineTo;
pub const bezierTo = js.bezierCurveTo;
pub fn fillColor(color: Color) void {
    js.fillColor(color.r, color.g, color.b, color.a);
}
pub const fill = js.fill;
pub fn fillPaint(paint: Paint) void {}
pub const stroke = js.stroke;
pub fn strokeWidth(width: f32) void {
    js.lineWidth(width);
}
pub fn lineJoin(join: LineJoin) void {
    js.lineJoin(@enumToInt(join));
}
pub fn fontFamily(name: []const u8) void {
    js.fontFamily(name.ptr, name.len);
}
pub fn fontSize(size: f32) void {
    js.fontSize(size);
} // TODO
var text_align: TextAlign = .left;
pub fn textAlign(algn: TextAlign) void {
    text_align = algn;
    js.textAlign(@enumToInt(algn));
}
pub fn text(str: []const u8, x: f32, y: f32) f32 {
    js.fillText(str.ptr, str.len, x, y);
    const w = js.measureText(str.ptr, str.len);
    return x + switch (text_align) {
        .left => w,
        .center => 0.5 * w,
        .right => 0,
    };
}
