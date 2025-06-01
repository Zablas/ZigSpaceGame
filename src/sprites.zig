const rl = @import("raylib");
const settings = @import("settings.zig");

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

    // pub fn update(self: *Sprite, delta_time: f64) void {}

    pub fn draw(self: Sprite) void {
        rl.drawTextureV(self.texture, self.position, .white);
    }
};

pub const Player = struct {
    base: Sprite,

    pub fn init(texture: rl.Texture, position: rl.Vector2) Player {
        return .{
            .base = Sprite.init(texture, position, settings.player_speed, rl.Vector2.zero()),
        };
    }

    pub fn draw(self: Player) void {
        self.base.draw();
    }
};
