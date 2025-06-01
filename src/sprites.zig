const rl = @import("raylib");

pub const Sprite = struct {
    texture: rl.Texture,
    position: rl.Vector2,
    speed: f32,
    direction: rl.Vector2,

    pub fn init(texture: rl.Texture, position: rl.Vector2, speed: f32, direction: rl.Vector2) Sprite {
        return .{
            .texture = texture,
            .position = position,
            .speed = speed,
            .direction = direction,
        };
    }
};
