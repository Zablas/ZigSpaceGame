const rl = @import("raylib");
const settings = @import("settings.zig");

pub const Sprite = struct {
    const Self = @This();

    texture: rl.Texture,
    position: rl.Vector2,
    speed: f32,
    direction: rl.Vector2,
    size: rl.Vector2,

    pub fn init(texture: rl.Texture, position: rl.Vector2, speed: f32, direction: rl.Vector2) Sprite {
        const size = rl.Vector2.init(@floatFromInt(texture.width), @floatFromInt(texture.height));

        return .{
            .texture = texture,
            .position = rl.Vector2.init(position.x - size.x / 2, position.y - size.y / 2),
            .speed = speed,
            .direction = direction,
            .size = size,
        };
    }

    // pub fn update(self: *Sprite, delta_time: f64) void {}

    pub fn draw(self: Self) void {
        rl.drawTextureV(self.texture, self.position, .white);
    }

    pub fn move(self: *Self, delta_time: f32) void {
        self.position.x += self.direction.x * self.speed * delta_time;
        self.position.y += self.direction.y * self.speed * delta_time;
    }
};

pub const Player = struct {
    const Self = @This();
    base: Sprite,

    pub fn init(texture: rl.Texture, position: rl.Vector2) Player {
        return .{
            .base = Sprite.init(texture, position, settings.player_speed, rl.Vector2.zero()),
        };
    }

    pub fn draw(self: Self) void {
        self.base.draw();
    }

    pub fn update(self: *Self, delta_time: f32) void {
        self.input();
        self.base.move(delta_time);
    }

    fn constraint(self: *Self) void {
        self.base.position.x = @max(0, @min(self.base.position.x, settings.window_width - self.base.size.x));
        self.base.position.y = @max(0, @min(self.base.position.y, settings.window_height - self.base.size.y));
    }

    fn input(self: *Self) void {
        self.base.direction.x = @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.right)))) - @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.left))));
        self.base.direction.y = @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.down)))) - @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.up))));
        self.base.direction = self.base.direction.normalize();
        self.constraint();
    }
};
