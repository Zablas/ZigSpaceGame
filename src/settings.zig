const rl = @import("raylib");

pub const window_height = 1080.0;
pub const window_width = 1920.0;
pub const bg_color = rl.Color.init(15, 10, 25, 255);
pub const player_speed = 500.0;
pub const laser_speed = 600;
pub const meteor_speed_range = [_]f32{ 300, 400 };
pub const meteor_timer_duration = 0.4;
pub const font_size = 120;
