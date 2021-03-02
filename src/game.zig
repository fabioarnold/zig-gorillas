const std = @import("std");
const nvg = @import("nvg.zig");
const gfx = @import("gfx.zig");

const Game = @This();

const GameState = enum(u1) {
    title,
    play,
};

const BuildingColor = enum(u2) {
    grey,
    teal,
    red,
};

const Building = struct {
    const Hole = struct {
        x: f32,
        y: f32,
        r: f32,
    };

    x: f32,
    y: f32,
    w: f32,
    h: f32,
    color: BuildingColor,

    holes: std.ArrayList(Hole),

    fn init(allocator: *std.mem.Allocator, x: f32, y: f32, w: f32, h: f32, color: BuildingColor) !*Building {
        var self = try allocator.create(Building);
        self.* = Building{
            .x = x,
            .y = y,
            .w = w,
            .h = h,
            .color = color,
            .holes = std.ArrayList(Hole).init(allocator),
        };
        return self;
    }

    fn deinit(self: Building) void {
        self.holes.deinit();
    }

    fn addHole(self: *Building, x: f32, y: f32, r: f32) void {
        self.holes.append(Hole{ .x = x, .y = y, .r = r }) catch unreachable;
    }

    fn hit(self: *Building, x: f32, y: f32, r: f32) bool {
        const wh = 0.5 * self.w;
        const hh = 0.5 * self.h;
        var dist = sdRect(x - (self.x + wh), y - (self.y + hh), wh, hh);

        if (dist < r) {
            for (self.holes.items) |hole| {
                const holeDist = sdCircle(x - hole.x, y - hole.y, hole.r);
                dist = sdSubtraction(dist, holeDist);
            }

            if (dist < r) {
                self.addHole(x, y, 48);
                return true;
            }
        }
        return false;
    }

    fn draw(self: Building) void {
        nvg.scissor(self.x, self.y, self.w, self.h);
        defer nvg.resetScissor();

        nvg.beginPath();
        nvg.rect(self.x + 4, self.y + 4, self.w - 8, self.h);
        nvg.strokeWidth(10);
        nvg.stroke();
        nvg.fillColor(switch (self.color) {
            .grey => nvg.rgb(168, 168, 168),
            .teal => nvg.rgb(96, 200, 136),
            .red => nvg.rgb(168, 0, 0),
        });
        nvg.fill();

        // windows
        const seed = @floatToInt(u64, self.x); // stable
        var pcg = std.rand.Pcg.init(seed);
        nvg.beginPath();
        var wy = self.y;
        while (wy < self.y + self.h) : (wy += 40) {
            var wx = self.x + 0.5 * @rem(self.w, 30);
            while (wx + 15 < self.x + self.w) : (wx += 30) {
                const on = pcg.random.uintLessThan(u8, 100) < 70;
                if (on) nvg.rect(wx + 10, wy + 18, 12, 20);
            }
        }
        nvg.fillColor(nvg.rgb(255, 255, 0));
        nvg.fill();
        pcg = std.rand.Pcg.init(seed);
        nvg.beginPath();
        wy = self.y;
        while (wy < self.y + self.h) : (wy += 40) {
            var wx = self.x + 0.5 * @rem(self.w, 30);
            while (wx + 15 < self.x + self.w) : (wx += 30) {
                const on = pcg.random.uintLessThan(u8, 100) < 70;
                if (!on) nvg.rect(wx + 10, wy + 18, 12, 20);
            }
        }
        nvg.fillColor(nvg.rgb(80, 80, 80));
        nvg.fill();

        // holes
        nvg.beginPath();
        for (self.holes.items) |hole| {
            nvg.circle(hole.x, hole.y, hole.r - 4);
        }
        nvg.stroke();
        nvg.scissor(self.x - 1, self.y - 1, self.w + 2, self.h + 2); // HACK
        nvg.fillColor(nvg.rgbf(0.3, 0.5, 0.8)); // background color
        nvg.fill();
    }
};

const TextEntry = enum(u2) {
    player1_name,
    player2_name,
    angle,
    velocity,
};

const world_width: f32 = 1920;
const world_height: f32 = 1080;
const player_r: f32 = 48;
const banana_r: f32 = 16 - 4;
const wind_max: f32 = 0.002;

allocator: *std.mem.Allocator,
width: f32 = 1280,
height: f32 = 720,

state: GameState = .title,

player_turn: u2 = 1,
player_win: u2 = 0,
player1_name: std.ArrayList(u8),
player1_x: f32 = undefined,
player1_y: f32 = undefined,
player1_arm: u8 = 0,
player2_name: std.ArrayList(u8),
player2_x: f32 = undefined,
player2_y: f32 = undefined,
player2_arm: u8 = 0,

banana_x: f32 = undefined,
banana_y: f32 = undefined,
banana_vx: f32 = undefined,
banana_vy: f32 = undefined,
banana_flying: bool = false,

explosion_x: f32 = undefined,
explosion_y: f32 = undefined,
explosion_r: f32 = undefined,
explosion_frames: u32 = 0,

wind: f32 = 0,

text_entry: TextEntry = .player1_name,
text_buffer: std.ArrayList(u8),
angle: u32 = 45,
velocity: u32 = 50,

buildings: std.ArrayList(*Building),

screenshake_amplitude: f32 = 0,
screenshake_frequency: f32 = 0,
frame: usize = 0,
rng: std.rand.Pcg = undefined,

pub fn init(allocator: *std.mem.Allocator) !Game {
    var self = Game{
        .allocator = allocator,
        .player1_name = std.ArrayList(u8).init(allocator),
        .player2_name = std.ArrayList(u8).init(allocator),
        .text_buffer = std.ArrayList(u8).init(allocator),
        .buildings = std.ArrayList(*Building).init(allocator),
    };

    try self.player1_name.appendSlice("Player 1");
    try self.player2_name.appendSlice("Player 2");

    const seed: u64 = @intCast(u64, std.time.milliTimestamp());
    self.rng = std.rand.Pcg.init(seed);

    try self.reset();

    return self;
}

pub fn deinit(self: *Game) void {
    self.player1_name.deinit();
    self.player2_name.deinit();
    self.text_buffer.deinit();
    self.clearBuildings();
    self.buildings.deinit();
}

fn reset(self: *Game) !void {
    self.state = .title;
    self.text_entry = .player1_name;
    self.player_win = 0;
    self.player_turn = 1;
    self.frame = 0;
    try self.generateBuildings(12);
    self.randomizeWind();
}

pub fn setSize(self: *Game, width: f32, height: f32) void {
    self.width = width;
    self.height = height;
}

pub fn onTextInput(self: *Game, text: []const u8) !void {
    switch (self.text_entry) {
        .player1_name => if (self.player1_name.items.len + text.len < 16) try self.player1_name.appendSlice(text),
        .player2_name => if (self.player2_name.items.len + text.len < 16) try self.player2_name.appendSlice(text),
        else => {
            if (self.banana_flying or self.player_win != 0) return;

            if (self.text_buffer.items.len >= 3) return;
            const c = text[0];
            if (c >= '0' and c <= '9') {
                try self.text_buffer.append(c);
            }
        },
    }
}

pub fn onKeyBackspace(self: *Game) void {
    switch (self.text_entry) {
        .player1_name => {if (self.player1_name.items.len > 0) self.player1_name.items.len -= 1;},
        .player2_name => {if (self.player2_name.items.len > 0) self.player2_name.items.len -= 1;},
        else => {if (self.text_buffer.items.len > 0) self.text_buffer.items.len -= 1;},
    }
}

pub fn onKeyReturn(self: *Game) void {
    switch (self.state) {
        .title => {
            switch (self.text_entry) {
                .player1_name => {
                    if (self.player1_name.items.len > 0) self.text_entry = .player2_name;
                },
                .player2_name => {
                    if (self.player1_name.items.len > 0) {
                        self.state = .play;
                        self.text_entry = .angle;
                    }
                },
                else => unreachable,
            }
        },
        .play => {
            if (self.banana_flying) return;

            if (self.player_win != 0) {
                self.reset() catch unreachable;
            } else {
                if (self.text_entry == .angle) {
                    if (self.text_buffer.items.len == 0) return;
                    self.angle = std.fmt.parseInt(u32, self.text_buffer.items, 10) catch unreachable;
                    self.text_buffer.items.len = 0;
                    self.text_entry = .velocity;
                } else if (self.text_entry == .velocity) {
                    if (self.text_buffer.items.len == 0) return;
                    self.velocity = std.fmt.parseInt(u32, self.text_buffer.items, 10) catch unreachable;
                    self.text_buffer.items.len = 0;
                    self.text_entry = .angle;
                    self.launchBanana(self.player_turn, @intToFloat(f32, self.angle), @intToFloat(f32, self.velocity));
                }
            }
        },
    }
}

fn clearBuildings(self: *Game) void {
    for (self.buildings.items) |building| {
        building.deinit();
        self.allocator.destroy(building);
    }
    self.buildings.items.len = 0;
}

fn generateBuildings(self: *Game, n: usize) !void {
    self.clearBuildings();
    try self.buildings.ensureCapacity(n);

    var total_width: f32 = 0;
    const spacing: f32 = 12;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        const color = @intToEnum(BuildingColor, self.rng.random.uintLessThan(u2, @typeInfo(BuildingColor).Enum.fields.len));
        const width = @intToFloat(f32, self.rng.random.intRangeAtMost(i32, 120, 250));
        const height = @intToFloat(f32, self.rng.random.intRangeAtMost(i32, 200, 750));
        self.buildings.appendAssumeCapacity(try Building.init(self.allocator, total_width, world_height - height, width, height, color));
        total_width += width;
    }
    const s = (world_width - @intToFloat(f32, n - 1) * spacing) / total_width;
    var x: f32 = 0;
    for (self.buildings.items) |building| {
        building.x = x;
        building.w *= s;
        x += building.w + spacing;
    }

    const building1 = self.buildings.items[1];
    const building2 = self.buildings.items[n - 2];
    self.player1_x = building1.x + 0.5 * building1.w;
    self.player1_y = building1.y;
    self.player2_x = building2.x + 0.5 * building2.w;
    self.player2_y = building2.y;
}

fn randomizeWind(self: *Game) void {
    self.wind = wind_max * (self.rng.random.float(f32) * 2 - 1);
}

fn launchBanana(self: *Game, player: u2, angle: f32, velocity: f32) void {
    const rad = angle * std.math.pi / 180;
    const power = std.math.clamp(velocity, 1, 100) / 20;
    if (player == 1) {
        self.player1_arm = 20;
        self.banana_x = self.player1_x + 10 - player_r;
        self.banana_y = self.player1_y - 10 - 2 * player_r;
        self.banana_vx = @cos(rad) * power;
        self.banana_vy = -@sin(rad) * power;
    } else if (player == 2) {
        self.player2_arm = 20;
        self.banana_x = self.player2_x - 10 + player_r;
        self.banana_y = self.player2_y - 10 - 2 * player_r;
        self.banana_vx = -@cos(rad) * power;
        self.banana_vy = -@sin(rad) * power;
    }
    self.banana_flying = true;
}

fn checkBuildingCollision(self: *Game, x: f32, y: f32, r: f32) bool {
    for (self.buildings.items) |building| {
        if (building.hit(x, y, r)) {
            return true;
        }
    }
    return false;
}

fn explode(self: *Game, x: f32, y: f32, r: f32) void {
    self.explosion_x = x;
    self.explosion_y = y;
    self.explosion_r = r;
    self.explosion_frames = 30;
}

pub fn tick(self: *Game) void {
    if (self.banana_flying) {
        self.banana_x += self.banana_vx;
        self.banana_y += self.banana_vy;
        self.banana_vx += self.wind;
        self.banana_vy += 0.004; // gravity

        const oob = self.banana_x < -banana_r or self.banana_x > world_width + banana_r;
        if (oob or self.checkBuildingCollision(self.banana_x, self.banana_y, banana_r)) {
            self.explode(self.banana_x, self.banana_y, 48);
            self.banana_flying = false;
            self.randomizeWind();
            self.player_turn = 3 - self.player_turn;
        } else { // check player collision
            if (self.player_turn == 1) {
                const d_x = self.player2_x - self.banana_x;
                const d_y = self.player2_y - player_r - self.banana_y;
                if (d_x * d_x + d_y * d_y < player_r * player_r) {
                    self.explode(self.player2_x, self.player2_y - player_r, 3 * player_r);
                    for (self.buildings.items) |building| building.addHole(self.explosion_x, self.explosion_y, self.explosion_r);
                    self.banana_flying = false;
                    self.player_win = self.player_turn;
                }
            } else if (self.player_turn == 2) {
                const d_x = self.player1_x - self.banana_x;
                const d_y = self.player1_y - player_r - self.banana_y;
                if (d_x * d_x + d_y * d_y < player_r * player_r) {
                    self.explode(self.player1_x, self.player1_y - player_r, 3 * player_r);
                    for (self.buildings.items) |building| building.addHole(self.explosion_x, self.explosion_y, self.explosion_r);
                    self.banana_flying = false;
                    self.player_win = self.player_turn;
                }
            }
        }
    }

    if (self.player1_arm > 0) self.player1_arm -= 1;
    if (self.player2_arm > 0) self.player2_arm -= 1;
    if (self.explosion_frames > 0) self.explosion_frames -= 1;

    self.screenshake_frequency = 0.8;
    self.screenshake_amplitude = @intToFloat(f32, self.explosion_frames);

    self.frame += 1;
}

fn drawParametersEntry(self: Game) void {
    nvg.save();
    defer nvg.restore();
    if (self.player_turn == 2) nvg.translate(self.width - 330, 0);

    const cursor_blink = self.frame % 60 < 30;
    var buf: [20]u8 = undefined;
    var x = nvg.text(10, 80, "Angle:");
    if (self.text_entry == .angle) {
        if (self.text_buffer.items.len > 0) x = nvg.text(x, 80, self.text_buffer.items);
        if (cursor_blink) _ = nvg.text(x, 80, "_");
    } else {
        _ = nvg.text(x, 80, std.fmt.bufPrint(&buf, "{}", .{self.angle}) catch unreachable);
    }
    x = nvg.text(10, 110, "Velocity:");
    if (self.text_entry == .velocity) {
        if (self.text_buffer.items.len > 0) x = nvg.text(x, 110, self.text_buffer.items);
        if (cursor_blink) _ = nvg.text(x, 110, "_");
    }
}

fn drawTitle(self: Game) void {
    const s = self.width / world_width;
    nvg.translate(0, (self.height - s * world_height) / 2);
    nvg.scale(s, s);
    nvg.save();

    nvg.translate(300, 250);
    nvg.scale(4, 4);
    gfx.drawHighVoltage();
    nvg.translate((world_width - 600) / 4, 0);
    gfx.drawHighVoltage();

    nvg.restore();

    nvg.fillColor(nvg.rgbf(1, 1, 1));
    nvg.fontSize(96);
    nvg.textAlign(.center);
    _ = nvg.text(world_width / 2, 300, "Zig Gorillas");
    _ = nvg.text(world_width / 2, 600, "VS");

    nvg.fontSize(48);
    var x1: f32 = 600;
    if (self.player1_name.items.len > 0) x1 = nvg.text(x1, 800, self.player1_name.items);
    var x2: f32 = world_width - 600;
    if (self.player2_name.items.len > 0) x2 = nvg.text(x2, 800, self.player2_name.items);
    nvg.textAlign(.left);
    if (self.frame % 60 < 30) _ = nvg.text(if (self.text_entry == .player1_name) x1 else x2, 800, "_");

    nvg.scale(2, 2);
    gfx.drawGorilla(600 / 2, 320, self.frame % 60 < 30, true);
    gfx.drawGorilla((world_width - 600) / 2, 320, self.frame % 60 >= 30, true);
}

fn drawWindIndicator(self: Game) void {
    const b = self.buildings.items[self.buildings.items.len / 2];
    const x = b.x + b.w / 2;
    const y = b.y;
    const h = 96;
    nvg.beginPath();
    nvg.moveTo(x, y);
    nvg.lineTo(x, y - h);
    nvg.strokeWidth(4);
    nvg.stroke();
    nvg.beginPath();
    nvg.moveTo(x, y - h);
    nvg.lineTo(x, y - h + 24);
    nvg.lineTo(x + 64 * self.wind / wind_max, y - h + 12 + 8 * std.math.sin(0.06 * @intToFloat(f32, self.frame)));
    nvg.closePath();
    nvg.fillColor(nvg.rgbf(1, 0, 0));
    nvg.fill();
    nvg.lineJoin(.Round);
    nvg.stroke();
}

fn drawGameplay(self: Game) void {
    // background
    nvg.beginPath();
    nvg.rect(0, 0, self.width, self.height);
    nvg.fillPaint(nvg.linearGradient(0, 0, 0, self.height, nvg.rgb(2, 124, 255), nvg.rgb(153, 202, 255)));
    nvg.fill();

    // player names
    nvg.fillColor(nvg.rgbf(1, 1, 1));
    nvg.fontSize(24);
    _ = nvg.text(10, 34, self.player1_name.items);
    _ = nvg.textAlign(.right);
    _ = nvg.text(self.width - 10, 34, self.player2_name.items);
    _ = nvg.textAlign(.left);

    if (self.player_win == 1) {
        _ = nvg.text(10, 80, "WIN");
    } else if (self.player_win == 2) {
        _ = nvg.textAlign(.right);
        _ = nvg.text(self.width - 10, 80, "WIN");
        _ = nvg.textAlign(.left);
    } else {
        if (!self.banana_flying) {
            self.drawParametersEntry();
        }
    }

    nvg.save();
    defer nvg.restore();
    const s = self.width / world_width;
    nvg.translate(0, self.height - s * world_height);
    nvg.scale(s, s);
    const screenshake = @sin(self.screenshake_frequency * @intToFloat(f32, self.frame)) * self.screenshake_amplitude;
    nvg.translate(screenshake, 0);

    gfx.drawSun(world_width / 2, world_height - 970, self.banana_flying, self.banana_x, self.banana_y);

    for (self.buildings.items) |building| {
        building.draw();
    }
    self.drawWindIndicator();

    if (self.player_win == 1) {
        gfx.drawGorilla(self.player1_x, self.player1_y, self.frame % 20 < 10, true);
    } else if (self.player_win == 2) {
        gfx.drawGorilla(self.player2_x, self.player2_y, self.frame % 20 < 10, true);
    } else {
        gfx.drawGorilla(self.player1_x, self.player1_y, false, self.player1_arm > 0);
        gfx.drawGorilla(self.player2_x, self.player2_y, true, self.player2_arm > 0);
    }

    if (self.banana_flying) {
        gfx.drawBanana(self.banana_x, self.banana_y, @intToFloat(f32, self.frame) * 0.1);
    }

    if (self.explosion_frames > 0) {
        if (self.explosion_frames >= 25) {
            nvg.beginPath();
            nvg.circle(self.explosion_x, self.explosion_y, self.explosion_r);
            nvg.fillColor(nvg.rgbf(1, 1, 1));
            nvg.fill();
        } else if (self.explosion_frames <= 20) {
            gfx.drawExplosion(self.explosion_x, self.explosion_y, self.explosion_r);
        }
    }
}

pub fn draw(self: Game) void {
    switch (self.state) {
        .title => self.drawTitle(),
        .play => self.drawGameplay(),
    }
}

// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

fn sdCircle(x: f32, y: f32, r: f32) f32 {
    return std.math.sqrt(x * x + y * y) - r;
}

fn sdRect(x: f32, y: f32, hw: f32, hh: f32) f32 {
    const q_x = std.math.absFloat(x) - hw;
    const q_y = std.math.absFloat(y) - hh;
    const q_x0 = std.math.max(q_x, 0);
    const q_y0 = std.math.max(q_y, 0);
    return std.math.sqrt(q_x0 * q_x0 + q_y0 * q_y0) + std.math.min(std.math.max(q_x, q_y), 0.0);
}

fn sdSubtraction(d1: f32, d2: f32) f32 {
    return std.math.max(d1, -d2);
}
