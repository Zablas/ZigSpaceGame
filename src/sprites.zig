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

    pub fn move(self: *Sprite, delta_time: f32) void {
        self.position.x += self.direction.x * self.speed * delta_time;
        self.position.y += self.direction.y * self.speed * delta_time;
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

    pub fn update(self: *Player, delta_time: f32) void {
        self.input();
        self.base.move(delta_time);
    }

    fn input(self: *Player) void {
        self.base.direction.x = @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.right)))) - @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.left))));
        self.base.direction.y = @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.down)))) - @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.up))));
        self.base.direction = self.base.direction.normalize();
    }
};
