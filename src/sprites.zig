const std = @import("std");
const rl = @import("raylib");
const settings = @import("settings.zig");

pub const Sprite = struct {
    const Self = @This();

    texture: rl.Texture,
    position: rl.Vector2,
    speed: f32,
    direction: rl.Vector2,
    size: rl.Vector2,
    discard: bool = false,
    collision_radius: f32,

    pub fn init(texture: rl.Texture, position: rl.Vector2, speed: f32, direction: rl.Vector2) Self {
        const size = rl.Vector2.init(@floatFromInt(texture.width), @floatFromInt(texture.height));

        return .{
            .texture = texture,
            .position = rl.Vector2.init(position.x - size.x / 2, position.y - size.y / 2),
            .speed = speed,
            .direction = direction,
            .size = size,
            .collision_radius = size.y / 2,
        };
    }

    pub fn update(self: *Sprite, delta_time: f32) void {
        self.checkDiscard();
        self.move(delta_time);
    }

    pub fn draw(self: Self) void {
        rl.drawTextureV(self.texture, self.position, .white);
    }

    pub fn move(self: *Self, delta_time: f32) void {
        self.position.x += self.direction.x * self.speed * delta_time;
        self.position.y += self.direction.y * self.speed * delta_time;
    }

    fn checkDiscard(self: *Self) void {
        self.discard = !(-300 < self.position.y and self.position.y < settings.window_height + 300);
    }
};

pub const Player = struct {
    const Self = @This();

    base: Sprite,
    shoot_laser: *const fn (rl.Vector2) anyerror!void,

    pub fn init(texture: rl.Texture, position: rl.Vector2, shoot_laser: *const fn (rl.Vector2) anyerror!void) Self {
        return .{
            .base = Sprite.init(texture, position, settings.player_speed, rl.Vector2.zero()),
            .shoot_laser = shoot_laser,
        };
    }

    pub fn draw(self: Self) void {
        self.base.draw();
    }

    pub fn update(self: *Self, delta_time: f32) !void {
        try self.input();
        self.base.move(delta_time);
        self.constraint();
    }

    fn constraint(self: *Self) void {
        self.base.position.x = @max(0, @min(self.base.position.x, settings.window_width - self.base.size.x));
        self.base.position.y = @max(0, @min(self.base.position.y, settings.window_height - self.base.size.y));
    }

    fn input(self: *Self) !void {
        self.base.direction.x = @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.right)))) - @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.left))));
        self.base.direction.y = @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.down)))) - @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.up))));
        self.base.direction = self.base.direction.normalize();

        if (rl.isKeyPressed(.space)) {
            try self.shoot_laser(rl.Vector2.init(self.base.position.x + self.base.size.x / 2, self.base.position.y - 60));
        }
    }

    pub fn getCenter(self: Self) rl.Vector2 {
        return rl.Vector2.init(self.base.position.x + self.base.size.x / 2, self.base.position.y + self.base.size.y / 2);
    }
};

pub const Laser = struct {
    const Self = @This();
    base: Sprite,

    pub fn init(texture: rl.Texture, position: rl.Vector2) Self {
        return .{
            .base = Sprite.init(texture, position, settings.laser_speed, rl.Vector2.init(0, -1)),
        };
    }

    pub fn draw(self: Self) void {
        self.base.draw();
    }

    pub fn update(self: *Self, delta_time: f32) void {
        self.base.update(delta_time);
    }

    pub fn getRectangle(self: Self) rl.Rectangle {
        return rl.Rectangle.init(self.base.position.x, self.base.position.y, self.base.size.x, self.base.size.y);
    }
};

pub const Meteor = struct {
    const Self = @This();

    base: Sprite,
    rotation: f32 = 0,
    rectangle: rl.Rectangle,

    pub fn init(texture: rl.Texture) !Self {
        var prng = std.Random.DefaultPrng.init(blk: {
            var seed: u64 = undefined;
            try std.posix.getrandom(std.mem.asBytes(&seed));
            break :blk seed;
        });
        const rand = prng.random();

        const position = rl.Vector2.init(
            @floatFromInt(rand.intRangeAtMost(i32, 0, settings.window_width)),
            @floatFromInt(rand.intRangeAtMost(i32, -150, -50)),
        );
        const direction = rl.Vector2.init(rand.float(f32) * (0.5 + 0.5) - 0.5, 1);
        const speed = settings.meteor_speed_range[rand.intRangeAtMost(usize, 0, 1)];

        const base = Sprite.init(texture, position, speed, direction);
        return .{
            .base = base,
            .rectangle = rl.Rectangle.init(0, 0, base.size.x, base.size.y),
        };
    }

    pub fn update(self: *Self, delta_time: f32) void {
        self.base.update(delta_time);
        self.rotation += 50 * delta_time;
    }

    pub fn getCenter(self: Self) rl.Vector2 {
        return self.base.position;
    }

    pub fn draw(self: Self) void {
        const destination_rectangle = rl.Rectangle.init(self.base.position.x, self.base.position.y, self.base.size.x, self.base.size.y);
        rl.drawTexturePro(
            self.base.texture,
            self.rectangle,
            destination_rectangle,
            rl.Vector2.init(self.base.size.x / 2, self.base.size.y / 2),
            self.rotation,
            .white,
        );
    }
};

pub const ExplosionAnimation = struct {
    const Self = @This();

    textures: std.ArrayList(rl.Texture),
    size: rl.Vector2,
    position: rl.Vector2,
    index: f32 = 0,
    discard: bool = false,

    pub fn init(position: rl.Vector2, textures: std.ArrayList(rl.Texture)) Self {
        const size = rl.Vector2.init(@floatFromInt(textures.items[0].width), @floatFromInt(textures.items[0].height));

        return .{
            .textures = textures,
            .size = size,
            .position = rl.Vector2.init(position.x - size.x / 2, position.y - size.y / 2),
        };
    }

    pub fn draw(self: Self) void {
        rl.drawTextureV(self.textures.items[@intFromFloat(self.index)], self.position, .white);
    }

    pub fn update(self: *Self, delta_time: f32) void {
        if (@as(usize, @intFromFloat(self.index)) < self.textures.items.len - 1) {
            self.index += 20 * delta_time;
        } else {
            self.discard = true;
        }
    }
};
