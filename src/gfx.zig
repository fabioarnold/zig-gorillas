const std = @import("std");
const nvg = @import("nvg.zig");

fn readNumber(data: []const u8, len: *usize) f32 {
    var i: usize = 0;
    while (i < data.len) : (i += 1) {
        if (!(data[i] == '.' or data[i] == '-' or (data[i] >= '0' and data[i] <= '9'))) break;
    }
    len.* = i;
    return std.fmt.parseFloat(f32, data[0..i]) catch unreachable;
}

fn fillPath(data: []const u8, color: nvg.Color) void {
    nvg.beginPath();
    //var odd: bool = false;
    var pos: usize = 0;
    var len: usize = 0;
    while (pos < data.len) {
        switch (data[pos]) {
            'M' => {
                //nvg.pathWinding(if (odd) .Clockwise else .CounterClockwise);
                //odd = !odd;
                pos += 1;
                const x = readNumber(data[pos..], &len);
                pos += len + 1;
                const y = readNumber(data[pos..], &len);
                pos += len;
                nvg.moveTo(x, y);
            },
            'L' => {
                pos += 1;
                const x = readNumber(data[pos..], &len);
                pos += len + 1;
                const y = readNumber(data[pos..], &len);
                pos += len;
                nvg.lineTo(x, y);
            },
            'C' => {
                pos += 1;
                const c1x = readNumber(data[pos..], &len);
                pos += len + 1;
                const c1y = readNumber(data[pos..], &len);
                pos += len + 1;
                const c2x = readNumber(data[pos..], &len);
                pos += len + 1;
                const c2y = readNumber(data[pos..], &len);
                pos += len + 1;
                const x = readNumber(data[pos..], &len);
                pos += len + 1;
                const y = readNumber(data[pos..], &len);
                pos += len;
                nvg.bezierTo(c1x, c1y, c2x, c2y, x, y);
            },
            'Z' => {
                pos += 1;
                nvg.closePath();
            },
            else => unreachable,
        }
    }

    nvg.fillColor(color);
    nvg.fill();
}

fn fillCircle(cx: f32, cy: f32, r: f32, color: nvg.Color) void {
    nvg.beginPath();
    nvg.circle(cx, cy, r);
    nvg.fillColor(color);
    nvg.fill();
}

pub fn drawGorilla(x: f32, y: f32, mirror_x: bool, arm_up: bool) void {
    nvg.save();
    defer nvg.restore();

    nvg.translate(if (mirror_x) x + 48 else x - 48, y - 96);
    if (mirror_x) nvg.scale(-1, 1);

    // outline
    if (arm_up) {
        fillPath("M72.98,49.57C74.904,51.488 76,54.309 76,57.4L76,58.343C73.67,59.167 72,61.39 72,64C72,64 72,72 72,72C72,75.311 74.689,78 78,78L86,78C91.519,78 96,73.519 96,68L96,51.841C96,34.846 82.656,20.942 65.883,20.047C65.961,19.544 66,19.027 66,18.5C66,16.475 65.425,14.583 64.431,12.978C61.72,4.583 55.833,0 48,0C40.146,0 34.263,4.553 31.557,13C30.571,14.597 30,16.482 30,18.5C30,19.009 30.037,19.51 30.109,20L29.4,20C23.736,20 20,15.264 20,9.6L20,8.657C22.33,7.833 24,5.61 24,3L24,-5C24,-8.311 21.311,-11 18,-11C18,-11 10,-11 10,-11C4.481,-11 0,-6.519 0,-1L0,15.159C0,29.664 9.722,41.916 23,45.753C23,45.753 23,49 23,49C23,53.967 27.033,58 32,58L64,58C68.776,58 72.688,54.272 72.98,49.57ZM17.215,4.839C16.767,5.582 16.382,6.285 16.171,6.677L16,7L16,9.6C16,17.548 21.452,24 29.4,24L34,24C34.001,22.629 34.066,21.319 34.191,20.071C34.066,19.568 34,19.042 34,18.5C34,17.092 34.449,15.788 35.211,14.723C37.247,7.865 41.755,4 48,4C54.23,4 58.74,7.894 60.782,14.713C61.549,15.78 62,17.088 62,18.5C62,19.039 61.934,19.564 61.81,20.065C61.937,21.315 62.001,22.628 62,24L64.159,24C79.525,24 92,36.475 92,51.841L92,68C92,71.311 89.311,74 86,74L78,74C76.896,74 76,73.104 76,72L76,64C76,62.896 76.896,62 78,62C79.095,62 79.986,62.882 80,63.974L80,64L80,57.4C80,50.281 75.625,44.361 69,43.205L69,49C69,51.76 66.76,54 64,54L32,54C29.24,54 27,51.76 27,49L27,42.58C13.937,40.284 4,28.873 4,15.159L4,-1C4,-4.311 6.689,-7 10,-7L18,-7C19.104,-7 20,-6.104 20,-5L20,3C20,4.104 19.104,5 18,5C17.721,5 17.456,4.943 17.215,4.839Z", nvg.rgb(0, 0, 0));
        fillPath("M16.917,83L14.25,83C10.801,83 8,85.801 8,89.25L8,96C8,98.209 9.791,100 12,100L36,100C38.209,100 40,98.209 40,96L40,89.25C40,87.441 39.23,85.812 38,84.67C38,84.671 38,81.632 38,81.632C38,81.632 46.654,73 46.654,73C46.654,73 49.346,73 49.346,73C49.346,73 58,81.632 58,81.632C58,81.632 58,84.671 58,84.671C56.77,85.812 56,87.441 56,89.25L56,96C56,98.209 57.791,100 60,100L84,100C86.209,100 88,98.209 88,96L88,89.25C88,85.801 85.199,83 81.75,83L79.083,83C79.673,81.618 80,80.097 80,78.5C80,74.331 77.962,71.879 74.46,68.804C74.466,68.809 67,61.343 67,61.343C67,61.343 67,54 67,54C67,51.791 65.209,50 63,50L33,50C30.791,50 29,51.791 29,54L29,61.343C29,61.343 21.534,68.809 21.534,68.809C18.036,71.881 16,74.333 16,78.5C16,80.097 16.327,81.618 16.917,83ZM63,54L63,63L71.731,71.731C74.255,73.939 76,75.517 76,78.5C76,79.991 75.564,81.38 74.813,82.548L72,87L81.75,87C82.992,87 84,88.008 84,89.25L84,96L60,96L60,89.25C60,88.093 60.876,87.138 62,87.014L62,79.972L51,69L45,69L34,79.972L34,87.014C35.124,87.138 36,88.093 36,89.25L36,96L12,96L12,89.25C12,88.008 13.008,87 14.25,87L24,87L21.187,82.548C20.436,81.38 20,79.991 20,78.5C20,75.517 21.745,73.939 24.269,71.731L33,63L33,54L63,54Z", nvg.rgb(0, 0, 0));
    } else {
        fillPath("M29,57.485L29,61.343C29,61.343 21.534,68.809 21.534,68.809C18.036,71.881 16,74.333 16,78.5C16,80.097 16.327,81.618 16.917,83L14.25,83C10.801,83 8,85.801 8,89.25L8,96C8,98.209 9.791,100 12,100L36,100C38.209,100 40,98.209 40,96L40,89.25C40,87.441 39.23,85.812 38,84.67C38,84.671 38,81.632 38,81.632C38,81.632 46.654,73 46.654,73C46.654,73 49.346,73 49.346,73C49.346,73 58,81.632 58,81.632C58,81.632 58,84.671 58,84.671C56.77,85.812 56,87.441 56,89.25L56,96C56,98.209 57.791,100 60,100L84,100C86.209,100 88,98.209 88,96L88,89.25C88,85.801 85.199,83 81.75,83L79.083,83C79.673,81.618 80,80.097 80,78.5C80,74.331 77.962,71.879 74.46,68.804C74.466,68.809 67,61.343 67,61.343L67,57.485C70.495,56.25 73,52.915 73,49L73,40C73,37.791 71.209,36 69,36L27,36C24.791,36 23,37.791 23,40L23,49C23,52.915 25.505,56.25 29,57.485ZM69,40L69,49C69,51.76 66.76,54 64,54L63,54L63,63L71.731,71.731C74.255,73.939 76,75.517 76,78.5C76,79.991 75.564,81.38 74.813,82.548L72,87L81.75,87C82.992,87 84,88.008 84,89.25L84,96L60,96L60,89.25C60,88.093 60.876,87.138 62,87.014L62,79.972L51,69L45,69L34,79.972L34,87.014C35.124,87.138 36,88.093 36,89.25L36,96L12,96L12,89.25C12,88.008 13.008,87 14.25,87L24,87L21.187,82.548C20.436,81.38 20,79.991 20,78.5C20,75.517 21.745,73.939 24.269,71.731L33,63L33,54L32,54C29.24,54 27,51.76 27,49L27,40L69,40Z", nvg.rgb(0, 0, 0));
        fillPath("M30.116,20.047C13.344,20.942 0,34.846 0,51.841L0,68C0,73.519 4.481,78 10,78L18,78C21.311,78 24,75.311 24,72L24,64C24,61.39 22.33,59.167 20,58.343L20,57.4C20,52.432 22.83,48.164 27.376,47.205C27.378,47.205 68.622,47.205 68.622,47.205L68.625,47.205C73.17,48.164 76,52.432 76,57.4L76,58.343C73.67,59.167 72,61.39 72,64C72,64 72,72 72,72C72,75.311 74.689,78 78,78L86,78C91.519,78 96,73.519 96,68L96,51.841C96,34.846 82.656,20.942 65.883,20.047C65.961,19.544 66,19.027 66,18.5C66,16.475 65.425,14.583 64.431,12.978C61.72,4.583 55.833,0 48,0C40.146,0 34.263,4.553 31.557,13C30.571,14.597 30,16.482 30,18.5C30,19.026 30.039,19.542 30.116,20.047ZM69,43.205L27,43.205C20.375,44.361 16,50.281 16,57.4L16,63.974C16.014,62.882 16.905,62 18,62C19.104,62 20,62.896 20,64L20,72C20,73.104 19.104,74 18,74L10,74C6.689,74 4,71.311 4,68L4,51.841C4,36.475 16.475,24 31.841,24L34,24C34.001,22.629 34.066,21.319 34.191,20.071C34.066,19.568 34,19.042 34,18.5C34,17.092 34.449,15.788 35.211,14.723C37.247,7.865 41.755,4 48,4C54.23,4 58.74,7.894 60.782,14.713C61.549,15.78 62,17.088 62,18.5C62,19.039 61.934,19.564 61.81,20.065C61.937,21.315 62.001,22.628 62,24L64.159,24C79.525,24 92,36.475 92,51.841L92,68C92,71.311 89.311,74 86,74L78,74C76.896,74 76,73.104 76,72L76,64C76,62.896 76.896,62 78,62C79.095,62 79.986,62.882 80,63.974L80,64L80,57.4C80,50.281 75.625,44.361 69,43.205Z", nvg.rgb(0, 0, 0));
    }

    // left arm
    if (arm_up) {
        fillPath("M48,43L48,24L29.4,24C21.452,24 16,17.548 16,9.6L16,2C16,1.448 15.552,1 15,1C14.448,1 14,1.448 14,2L14,3L4,3L4,15.159C4,30.525 16.475,43 31.841,43L48,43Z", nvg.rgb(118, 118, 118));
        fillPath("M16,3.026C16.014,4.118 16.905,5 18,5C19.104,5 20,4.104 20,3L20,-5C20,-6.104 19.104,-7 18,-7L10,-7C6.689,-7 4,-4.311 4,-1L4,3L16,3L16,3.026Z", nvg.rgb(205, 205, 205));
    } else {
        fillPath("M48,24L48,43L29.4,43C21.452,43 16,49.452 16,57.4L16,65C16,65.552 15.552,66 15,66C14.448,66 14,65.552 14,65L14,64L4,64L4,51.841C4,36.475 16.475,24 31.841,24L48,24Z", nvg.rgb(118, 118, 118));
        fillPath("M16,63.974C16.014,62.882 16.905,62 18,62C19.104,62 20,62.896 20,64L20,72C20,73.104 19.104,74 18,74L10,74C6.689,74 4,71.311 4,68L4,64L16,64L16,63.974Z", nvg.rgb(205, 205, 205));
    }
    // right arm
    fillPath("M48,24L48,43L66.6,43C74.548,43 80,49.452 80,57.4L80,65C80,65.552 80.448,66 81,66C81.552,66 82,65.552 82,65L82,64L92,64L92,51.841C92,36.475 79.525,24 64.159,24L48,24Z", nvg.rgb(118, 118, 118));
    fillPath("M80,63.974C79.986,62.882 79.095,62 78,62C76.896,62 76,62.896 76,64L76,72C76,73.104 76.896,74 78,74L86,74C89.311,74 92,71.311 92,68L92,64L80,64L80,63.974Z", nvg.rgb(205, 205, 205));

    // legs
    fillPath("M24.269,71.731L33,63L45,69L34,79.972L34,88L24,87L21.187,82.548L21.187,82.548C20.436,81.38 20,79.991 20,78.5C20,75.517 21.745,73.939 24.269,71.731Z", nvg.rgb(118, 118, 118));
    fillPath("M71.731,71.731L63,63L51,69L62,79.972L62,88L72,87L74.813,82.548L74.813,82.548C75.564,81.38 76,79.991 76,78.5C76,75.517 74.255,73.939 71.731,71.731Z", nvg.rgb(118, 118, 118));
    // feet
    fillPath("M36,96L36,89.25C36,88.008 34.992,87 33.75,87L14.25,87C13.008,87 12,88.008 12,89.25L12,96L36,96Z", nvg.rgb(205, 205, 205));
    fillPath("M60,96L60,89.25C60,88.008 61.008,87 62.25,87L81.75,87C82.992,87 84,88.008 84,89.25L84,96L60,96Z", nvg.rgb(205, 205, 205));

    // belly
    fillPath("M63,53.25C63,50.352 60.648,48 57.75,48L38.25,48C35.352,48 33,50.352 33,53.25L33,63.75C33,66.648 35.352,69 38.25,69L57.75,69C60.648,69 63,66.648 63,63.75L63,53.25Z", nvg.rgb(205, 205, 205));
    fillPath("M50,64C50,63.448 49.552,63 49,63L47,63C46.448,63 46,63.448 46,64C46,64.552 46.448,65 47,65L49,65C49.552,65 50,64.552 50,64Z", nvg.rgb(118, 118, 118));
    // chest
    fillPath("M33,31L33,56L42,56C45.863,56 49,52.863 49,49C49,49 49,38 49,38C49,34.137 45.863,31 42,31L33,31Z", nvg.rgb(118, 118, 118));
    fillPath("M47,38C47,35.24 44.76,33 42,33L32,33C29.24,33 27,35.24 27,38L27,49C27,51.76 29.24,54 32,54L42,54C44.76,54 47,51.76 47,49L47,38Z", nvg.rgb(205, 205, 205));
    fillCircle(32, 49, 1, nvg.rgb(118, 118, 118));
    fillPath("M63,31L63,56L54,56C50.137,56 47,52.863 47,49C47,49 47,38 47,38C47,34.137 50.137,31 54,31L63,31Z", nvg.rgb(118, 118, 118));
    fillPath("M49,38C49,35.24 51.24,33 54,33L64,33C66.76,33 69,35.24 69,38L69,49C69,51.76 66.76,54 64,54L54,54C51.24,54 49,51.76 49,49L49,38Z", nvg.rgb(205, 205, 205));
    fillCircle(64, 49, 1, nvg.rgb(118, 118, 118));

    // head
    fillPath("M48,4C39.333,4 34.012,11.443 34,24C33.992,32.569 41.691,36.99 48,37C54.309,37.01 61.996,32.488 62,24C62.006,11.536 56.667,4 48,4Z", nvg.rgb(118, 118, 118));
    fillPath("M40.5,12C36.913,12 34,14.913 34,18.5C34,20.009 34.515,21.4 35.38,22.503C34.49,24.022 34,25.717 34,27.5C34,33.707 40.16,39 48,39C55.84,39 62,33.707 62,27.5C62,25.717 61.51,24.022 60.62,22.503C61.485,21.399 62,20.009 62,18.5C62,14.913 59.087,12 55.5,12L40.5,12Z", nvg.rgb(118, 118, 118));
    fillPath("M40.5,14L55.5,14C57.984,14 60,16.016 60,18.5C60,20.061 59.204,21.437 57.995,22.244C59.262,23.75 60,25.557 60,27.5C60,32.743 54.623,37 48,37C41.377,37 36,32.743 36,27.5C36,25.557 36.738,23.75 38.005,22.244C36.796,21.437 36,20.061 36,18.5C36,16.016 38.016,14 40.5,14Z", nvg.rgb(205, 205, 205));
    fillPath("M39,18C39,17.448 39.448,17 40,17L44,17C44.548,17 44.993,17.441 45,17.987L45,18C45,19.656 43.656,21 42,21C40.344,21 39,19.656 39,18Z", nvg.rgb(0, 0, 0));
    fillPath("M51,18C51,17.448 51.448,17 52,17L56,17C56.548,17 56.993,17.441 57,17.987L57,18C57,19.656 55.656,21 54,21C52.344,21 51,19.656 51,18Z", nvg.rgb(0, 0, 0));
    fillPath("M40,32C39.448,32 39,31.552 39,31C39,29.344 40.344,28 42,28L54,28C55.656,28 57,29.344 57,31C57,31.552 56.552,32 56,32L40,32Z", nvg.rgb(0, 0, 0));
    fillCircle(45.5, 24.5, 1.5, nvg.rgb(0, 0, 0));
    fillCircle(50.5, 24.5, 1.5, nvg.rgb(0, 0, 0));
}

pub fn drawBanana(x: f32, y: f32, angle: f32) void {
    nvg.save();
    defer nvg.restore();

    nvg.translate(x, y);
    nvg.rotate(angle);
    nvg.translate(-16, -16);
    fillPath("M16,16.016C14.127,16.016 12.53,14.506 11.159,13.373C9.427,11.941 7.922,10.713 6.902,10.279C4.959,9.45 3.374,9.825 2.147,10.722C1.277,11.358 0.016,12.802 0.016,16C0.016,24.822 7.178,31.984 16,31.984C24.822,31.984 31.984,24.822 31.984,16C31.984,12.802 30.723,11.358 29.853,10.722C28.626,9.825 27.041,9.45 25.098,10.279C24.078,10.713 22.573,11.941 20.841,13.373C19.47,14.506 17.873,16.016 16,16.016ZM16,20C22.623,20 28,9.377 28,16C28,22.623 22.623,28 16,28C9.377,28 4,22.623 4,16C4,9.377 9.377,20 16,20Z", nvg.rgb(0, 0, 0));
    fillPath("M16,20C22.623,20 28,9.377 28,16C28,22.623 22.623,28 16,28C9.377,28 4,22.623 4,16C4,9.377 9.377,20 16,20Z", nvg.rgb(255, 217, 18));
    fillPath("M4.224,14.316C5.304,19.832 10.169,24 16,24C21.831,24 26.696,19.832 27.776,14.316C27.923,14.662 28,15.208 28,16C28,22.623 22.623,28 16,28C9.377,28 4,22.623 4,16C4,15.208 4.077,14.662 4.224,14.316Z", nvg.rgb(225, 166, 58));
}

pub fn drawExplosion(x: f32, y: f32, r: f32) void {
    nvg.save();
    defer nvg.restore();
    nvg.translate(x, y);

    const n: usize = 8;
    const angle: f32 = 2 * std.math.pi / @floatFromInt(f32, n);
    var k: usize = 0;
    while (k < 3) : (k += 1) {
        const kr = @floatFromInt(f32, 3 - k) * r / 3;
        nvg.beginPath();
        var i: usize = 0;
        while (i < n) : (i += 1) {
            const f = @floatFromInt(f32, i);
            var c = @cos(f * angle);
            var s = @sin(f * angle);
            if (i == 0) nvg.moveTo(kr * c, kr * s) else nvg.lineTo(kr * c, kr * s);
            c = @cos((f + 0.5) * angle);
            s = @sin((f + 0.5) * angle);
            nvg.lineTo(0.6 * kr * c, 0.6 * kr * s);
        }
        nvg.closePath();
        if (k == 0) {
            nvg.strokeWidth(8);
            nvg.stroke();
        }
        nvg.fillColor(switch (k) {
            0 => nvg.rgb(233, 10, 31),
            1 => nvg.rgb(255, 201, 58),
            2 => nvg.rgbf(1, 1, 1),
            else => unreachable,
        });
        nvg.fill();
    }
}

fn calcGaze(cx: f32, cy: f32, tx: f32, ty: f32, r_max: f32) struct { x: f32, y: f32 } {
    var dx = tx - cx;
    var dy = ty - cy;
    var len_sqr = dx * dx + dy * dy;
    if (len_sqr > r_max * r_max) {
        const s = r_max / std.math.sqrt(len_sqr);
        dx *= s;
        dy *= s;
    }
    return .{ .x = dx, .y = dy };
}

pub fn drawSun(x: f32, y: f32, gaze: bool, tx: f32, ty: f32) void {
    nvg.save();
    defer nvg.restore();
    nvg.translate(x - 48, y - 48);
    fillPath("M51.368,1.842C50.633,0.694 49.363,0 48,-0C46.637,-0 45.367,0.694 44.632,1.842L38.286,11.746C38.286,11.746 27.838,6.342 27.838,6.342C26.627,5.716 25.181,5.749 24,6.431C22.819,7.112 22.067,8.348 22.004,9.71L21.461,21.461C21.461,21.461 9.71,22.004 9.71,22.004C8.348,22.067 7.112,22.819 6.431,24C5.749,25.181 5.716,26.627 6.342,27.838L11.746,38.286C11.746,38.286 1.842,44.632 1.842,44.632C0.694,45.367 -0,46.637 -0,48C0,49.363 0.694,50.633 1.842,51.368L11.746,57.714C11.746,57.714 6.342,68.162 6.342,68.162C5.716,69.373 5.749,70.819 6.431,72C7.112,73.181 8.348,73.933 9.71,73.996L21.461,74.539C21.461,74.539 22.004,86.29 22.004,86.29C22.067,87.652 22.819,88.888 24,89.569C25.181,90.251 26.627,90.284 27.838,89.658L38.286,84.254C38.286,84.254 44.632,94.158 44.632,94.158C45.367,95.306 46.637,96 48,96C49.363,96 50.633,95.306 51.368,94.158L57.714,84.254C57.714,84.254 68.162,89.658 68.162,89.658C69.373,90.284 70.819,90.251 72,89.569C73.181,88.888 73.933,87.652 73.996,86.29L74.539,74.539C74.539,74.539 86.29,73.996 86.29,73.996C87.652,73.933 88.888,73.181 89.569,72C90.251,70.819 90.284,69.373 89.658,68.162L84.254,57.714C84.254,57.714 94.158,51.368 94.158,51.368C95.306,50.633 96,49.363 96,48C96,46.637 95.306,45.367 94.158,44.632L84.254,38.286C84.254,38.286 89.658,27.838 89.658,27.838C90.284,26.627 90.251,25.181 89.569,24C88.888,22.819 87.652,22.067 86.29,22.004L74.539,21.461C74.539,21.461 73.996,9.71 73.996,9.71C73.933,8.348 73.181,7.112 72,6.431C70.819,5.749 69.373,5.716 68.162,6.342L57.714,11.746C57.714,11.746 51.368,1.842 51.368,1.842ZM48,4L56.313,16.974L70,9.895L70.712,25.288L86.105,26L79.026,39.687L92,48L79.026,56.313L86.105,70L70.712,70.712L70,86.105L56.313,79.026L48,92L39.687,79.026L26,86.105L25.288,70.712L9.895,70L16.974,56.313L4,48L16.974,39.687L9.895,26L25.288,25.288L26,9.895L39.687,16.974L48,4Z", nvg.rgb(0, 0, 0));
    fillPath("M48,4L56.313,16.974L70,9.895L70.712,25.288L86.105,26L79.026,39.687L92,48L79.026,56.313L86.105,70L70.712,70.712L70,86.105L56.313,79.026L48,92L39.687,79.026L26,86.105L25.288,70.712L9.895,70L16.974,56.313L4,48L16.974,39.687L9.895,26L25.288,25.288L26,9.895L39.687,16.974L48,4Z", nvg.rgb(255, 186, 0));
    fillCircle(48, 48, 32, nvg.rgb(255, 225, 0));
    // mouth
    if (gaze) {
        fillCircle(48, 64, 5, nvg.rgb(0, 0, 0));
    } else {
        fillPath("M64,56.104C63.944,64.886 56.796,72 48,72C39.17,72 32,64.83 32,56L64,56L64,56.104Z", nvg.rgb(0, 0, 0));
        fillPath("M42.038,68.668C43.504,67.032 45.632,66 48,66C50.368,66 52.496,67.032 53.962,68.668C52.154,69.522 50.132,70 48,70C45.868,70 43.846,69.522 42.038,68.668Z", nvg.rgb(255, 0, 16));
        fillPath("M61.856,58C61.654,59.412 61.242,60.756 60.65,62L35.35,62C34.758,60.756 34.344,59.412 34.142,58L61.856,58Z", nvg.rgbf(1, 1, 1));
    }
    fillCircle(34, 42, 10, nvg.rgbf(1, 1, 1));
    fillCircle(62, 42, 10, nvg.rgbf(1, 1, 1));
    if (gaze) {
        const gl = calcGaze(x - 14, y - 6, tx, ty, 5);
        const gr = calcGaze(x + 14, y - 6, tx, ty, 5);
        fillCircle(34 + gl.x, 42 + gl.y, 5, nvg.rgb(0, 0, 0));
        fillCircle(62 + gr.x, 42 + gr.y, 5, nvg.rgb(0, 0, 0));
    } else {
        fillCircle(34, 42, 5, nvg.rgb(0, 0, 0));
        fillCircle(62, 42, 5, nvg.rgb(0, 0, 0));
    }
}

pub fn drawHighVoltage() void {
    nvg.beginPath();
    nvg.moveTo(3, -14);
    nvg.lineTo(-13, 2);
    nvg.lineTo(1, 2);
    nvg.lineTo(-3, 14);
    nvg.lineTo(13, -2);
    nvg.lineTo(-1, -2);
    nvg.closePath();
    nvg.lineJoin(.Round);
    nvg.strokeWidth(4);
    nvg.stroke();
    nvg.fillColor(nvg.rgb(255, 200, 61));
    nvg.fill();
}
