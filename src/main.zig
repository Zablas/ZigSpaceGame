const std = @import("std");
const rl = @import("raylib");
const Timer = @import("timer.zig").Timer;
const settings = @import("settings.zig");
const sprites = @import("sprites.zig");

const Star = struct { rl.Vector2, f32 };

var assets: std.StringHashMap(rl.Texture) = undefined;
var lasers: std.ArrayList(sprites.Laser) = undefined;
var meteors: std.ArrayList(sprites.Meteor) = undefined;
var explosions: std.ArrayList(sprites.ExplosionAnimation) = undefined;
var explosion_textures: std.ArrayList(rl.Texture) = undefined;
var laser_sound: rl.Sound = undefined;

pub fn main() !void {
    rl.initWindow(settings.window_width, settings.window_height, "raylib-zig [core] example - basic window");
    defer rl.closeWindow();

    rl.initAudioDevice();
    defer rl.closeAudioDevice();

    rl.setExitKey(.null);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    laser_sound = try rl.loadSound("assets/audio/laser.wav");
    defer rl.unloadSound(laser_sound);

    const explosion_sound = try rl.loadSound("assets/audio/explosion.wav");
    defer rl.unloadSound(explosion_sound);

    const music = try rl.loadMusicStream("assets/audio/music.wav");
    defer rl.unloadMusicStream(music);
    rl.playMusicStream(music);

    assets = std.StringHashMap(rl.Texture).init(allocator);
    defer assets.deinit();

    lasers = std.ArrayList(sprites.Laser).init(allocator);
    defer lasers.deinit();

    meteors = std.ArrayList(sprites.Meteor).init(allocator);
    defer meteors.deinit();

    try assets.put("player", try rl.loadTexture("assets/images/spaceship.png"));
    defer rl.unloadTexture(assets.get("player").?);

    try assets.put("star", try rl.loadTexture("assets/images/star.png"));
    defer rl.unloadTexture(assets.get("star").?);

    try assets.put("laser", try rl.loadTexture("assets/images/laser.png"));
    defer rl.unloadTexture(assets.get("laser").?);

    try assets.put("meteor", try rl.loadTexture("assets/images/meteor.png"));
    defer rl.unloadTexture(assets.get("meteor").?);

    const font = try rl.loadFontEx("assets/font/Stormfaze.otf", settings.font_size, null);
    defer rl.unloadFont(font);

    explosion_textures = std.ArrayList(rl.Texture).init(allocator);
    defer explosion_textures.deinit();

    for (1..29) |i| {
        const image_path = try std.fmt.allocPrintZ(allocator, "assets/images/explosion/{d}.png", .{i});
        defer allocator.free(image_path);

        try explosion_textures.append(try rl.loadTexture(image_path));
    }

    explosions = std.ArrayList(sprites.ExplosionAnimation).init(allocator);
    defer explosions.deinit();

    var meteor_timer = Timer.init(settings.meteor_timer_duration, true, true, createMeteor);

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

    var should_close = false;

    while (!rl.windowShouldClose() and !should_close) {
        const delta_time = rl.getFrameTime();

        meteor_timer.update();
        try player.update(delta_time);
        discardLasers();
        discardMeteors();
        discardExplosions();
        for (lasers.items) |*laser| {
            laser.update(delta_time);
        }

        for (meteors.items) |*meteor| {
            meteor.update(delta_time);
        }

        for (explosions.items) |*explosion| {
            explosion.update(delta_time);
        }

        should_close = checkCollisionsPlayerMeteors(player);
        try checkCollisionsLasersMeteors(explosion_sound);

        rl.updateMusicStream(music);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(settings.bg_color);

        drawStars(stars, assets.get("star").?);
        player.draw();
        for (lasers.items) |laser| {
            laser.draw();
        }

        for (meteors.items) |meteor| {
            meteor.draw();
        }

        for (explosions.items) |explosion| {
            explosion.draw();
        }

        drawScore(font);
    }
}

fn drawScore(font: rl.Font) void {
    const score: i64 = @intFromFloat(rl.getTime());
    const text = rl.textFormat("%d", .{score});
    const text_size = rl.measureTextEx(font, text, settings.font_size, 0);
    rl.drawTextEx(font, text, rl.Vector2.init(settings.window_width / 2 - text_size.x / 2, 100), settings.font_size, 0, .white);
}

fn drawStars(stars: std.ArrayList(Star), texture: rl.Texture) void {
    for (stars.items) |star| {
        rl.drawTextureEx(texture, star[0], 0, star[1], .white);
    }
}

fn shootLaser(position: rl.Vector2) !void {
    const laser = sprites.Laser.init(assets.get("laser").?, position);
    try lasers.append(laser);

    rl.playSound(laser_sound);
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

fn createMeteor() !void {
    const meteor = try sprites.Meteor.init(assets.get("meteor").?);
    try meteors.append(meteor);
}

fn discardMeteors() void {
    var i: usize = 0;
    while (i < meteors.items.len) {
        if (meteors.items[i].base.discard) {
            _ = meteors.swapRemove(i);
        } else {
            i += 1;
        }
    }
}

fn discardExplosions() void {
    var i: usize = 0;
    while (i < explosions.items.len) {
        if (explosions.items[i].discard) {
            _ = explosions.swapRemove(i);
        } else {
            i += 1;
        }
    }
}

fn checkCollisionsPlayerMeteors(player: sprites.Player) bool {
    for (meteors.items) |meteor| {
        if (rl.checkCollisionCircles(player.getCenter(), player.base.collision_radius, meteor.getCenter(), meteor.base.collision_radius)) {
            return true;
        }
    }

    return false;
}

fn checkCollisionsLasersMeteors(sound: rl.Sound) !void {
    for (lasers.items) |*laser| {
        for (meteors.items) |*meteor| {
            if (rl.checkCollisionCircleRec(meteor.getCenter(), meteor.base.collision_radius, laser.getRectangle())) {
                laser.base.discard = true;
                meteor.base.discard = true;

                const position = rl.Vector2.init(laser.base.position.x - laser.base.size.x / 2, laser.base.position.y);
                try explosions.append(sprites.ExplosionAnimation.init(position, explosion_textures));

                rl.playSound(sound);
            }
        }
    }
}
