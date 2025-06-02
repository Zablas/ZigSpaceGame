const std = @import("std");
const rl = @import("raylib");
const Timer = @import("timer.zig").Timer;
const settings = @import("settings.zig");
const sprites = @import("sprites.zig");

const Star = struct { rl.Vector2, f32 };

var assets: std.StringHashMap(rl.Texture) = undefined;
var lasers: std.ArrayList(sprites.Laser) = undefined;

pub fn main() !void {
    rl.initWindow(settings.window_width, settings.window_height, "raylib-zig [core] example - basic window");
    defer rl.closeWindow();

    rl.setExitKey(.null);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    assets = std.StringHashMap(rl.Texture).init(allocator);
    defer assets.deinit();

    lasers = std.ArrayList(sprites.Laser).init(allocator);
    defer lasers.deinit();

    try assets.put("player", try rl.loadTexture("assets/images/spaceship.png"));
    try assets.put("star", try rl.loadTexture("assets/images/star.png"));
    try assets.put("laser", try rl.loadTexture("assets/images/laser.png"));

    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    var stars = std.ArrayList(Star).init(allocator);
    defer stars.deinit();

    for (0..30) |_| {
        const star = Star{
            rl.Vector2.init(
                @floatFromInt(rand.intRangeAtMost(i32, 0, settings.window_width)),
                @floatFromInt(rand.intRangeAtMost(i32, 0, settings.window_height)),
            ),
            rand.float(f32) * (1.2 - 0.5) + 0.5,
        };
        try stars.append(star);
    }

    var player = sprites.Player.init(
        assets.get("player").?,
        rl.Vector2.init(settings.window_width / 2, settings.window_height / 2),
        shootLaser,
    );

    while (!rl.windowShouldClose()) {
        const delta_time = rl.getFrameTime();

        try player.update(delta_time);
        discardLasers();
        for (lasers.items) |*laser| {
            laser.update(delta_time);
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(settings.bg_color);

        drawStars(stars, assets.get("star").?);
        player.draw();
        for (lasers.items) |laser| {
            laser.draw();
        }
    }
}

fn drawStars(stars: std.ArrayList(Star), texture: rl.Texture) void {
    for (stars.items) |star| {
        rl.drawTextureEx(texture, star[0], 0, star[1], .white);
    }
}

fn shootLaser(position: rl.Vector2) !void {
    const laser = sprites.Laser.init(assets.get("laser").?, position);
    try lasers.append(laser);
}

fn discardLasers() void {
    var i: usize = 0;
    while (i < lasers.items.len) {
        if (lasers.items[i].base.discard) {
            _ = lasers.swapRemove(i);
        } else {
            i += 1;
        }
    }
}
