const std = @import("std");
const rl = @import("raylib");
const Timer = @import("timer.zig").Timer;

const window_height = 1920;
const window_width = 1080;
const bg_color = rl.Color.init(15, 10, 25, 255);
const player_speed = 500;
const laser_speed = 600;
const meteor_speed_range = [_]u8{ 300, 400 };
const meteor_timer_duration = 0.4;

pub fn main() void {
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second

    var timer = Timer.init(2, true, true, null);

    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        timer.update();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);

        rl.drawText("Congrats! You created your first window!", 190, 200, 20, .light_gray);
    }
}
