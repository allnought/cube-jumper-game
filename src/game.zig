const std = @import("std");
const rl = @import("raylib/raylib.zig");
const levels = @import("levels.zig");
const objects = @import("objects.zig");
const level1 = @import("levels/1.zig");

pub fn initMap(level: levels.levelData) objects.map {
    var map: [180]objects.tile = undefined;
    var iteration: u8 = 0;
    for (level.grid) |row, rowIndex| {
        for (row) |pos, posIndex| {
            if (pos != 0) {
                map[iteration] = objects.tile{
                    .rect = rl.Rectangle{
                        .x = @intToFloat(f32, posIndex * 50),
                        .y = @intToFloat(f32, rowIndex * 50),
                        .width = 50,
                        .height = 50,
                    },
                    .type = pos,
                };
                iteration += 1;
            }
        }
    }
    return objects.map{
        .grid = map[0..iteration],
        .spawnPos = level.spawnPos,
        .id = level.id,
    };
}

pub fn draw(map: objects.map, player: objects.player) void {
    rl.ClearBackground(rl.RAYWHITE);
    for (map.grid) |tile| {
        rl.DrawRectangleRec(tile.rect, switch (tile.type) {
            0 => rl.WHITE,
            1 => rl.BLACK,
            2 => rl.RED,
            3 => rl.LIME,
            4 => rl.YELLOW,
            5 => rl.GREEN,
            6 => rl.PURPLE,
            7 => rl.VIOLET,
            8 => rl.LIGHTGRAY,
            9 => rl.GOLD,
            else => rl.BLACK,
        });
    }
    rl.DrawRectangleRec(player.rect, rl.RED);
}

pub fn bounds(player: *objects.player, map: *objects.map, state: *u8) void {
    if (player.rect.x > 870) {
        const transitionTo = level1.transition(map.id);
        if (transitionTo[2].id != 255) {
            player.rect.x = 0;
            map.* = initMap(transitionTo[2]);
        } else player.rect.x = 870;
    } else if (player.rect.x < 0) {
        const transitionTo = level1.transition(map.id);
        if (transitionTo[0].id != 255) {
            map.* = initMap(transitionTo[0]);
            player.rect.x = 870;
        } else {
            player.rect.x = 0;
        }
    }
    if (player.rect.y < 0) {
        const transitionTo = level1.transition(map.id);
        if (transitionTo[1].id != 255) {
            player.rect.y = 440;
            map.* = initMap(transitionTo[1]);
        } else if (player.gravity < 0) {
            player.die(state);
        }
    }
    if (player.rect.y > 440) {
        const transitionTo = level1.transition(map.id);
        if (transitionTo[3].id != 255) {
            player.rect.y = 0;
            map.* = initMap(transitionTo[3]);
        } else if (player.gravity > 0) {
            player.die(state);
        }
    }
}
