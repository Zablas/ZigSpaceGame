const std = @import("std");
const rl = @import("raylib");
const Timer = @import("timer.zig").Timer;
const settings = @import("settings.zig");
const sprites = @import("sprites.zig");

pub fn main() !void {
    rl.initWindow(settings.window_width, settings.window_height, "raylib-zig [core] example - basic window");
    defer rl.closeWindow();

    rl.setExitKey(.null);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var assets = std.StringHashMap(rl.Texture).init(allocator);
    defer assets.deinit();

    try assets.put("player", try rl.loadTexture("assets/images/spaceship.png"));

    const player = sprites.Player.init(assets.get("player").?, rl.Vector2.init(settings.window_width / 2, settings.window_height / 2));

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(settings.bg_color);
        player.draw();
    }
}
