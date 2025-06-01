const std = @import("std");
const rl = @import("raylib");
const Timer = @import("timer.zig").Timer;
const settings = @import("settings.zig");

pub fn main() void {
    rl.initWindow(settings.window_width, settings.window_height, "raylib-zig [core] example - basic window");
    defer rl.closeWindow();

    rl.setExitKey(.null);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);

        rl.drawText("Congrats! You created your first window!", 190, 200, 20, .light_gray);
    }
}
