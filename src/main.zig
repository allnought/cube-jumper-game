const std = @import("std");
const rl = @import("raylib/raylib.zig");
const levels = @import("levels.zig");
const objects = @import("objects.zig");
const game = @import("game.zig");
const level1 = @import("levels/1.zig");

pub const gameState = enum { titleScreen, gameScreen, deathScreen, pauseScreen, levelBeatScreen };

pub fn main() void {
    const screenWidth: u16 = 900;
    const screenHeight: u16 = 500;

    rl.InitWindow(screenWidth, screenHeight, "Cube Jumper Game");
    rl.SetTargetFPS(60);
    rl.SetExitKey(.KEY_NULL);

    var exitGame: bool = false;
    var map: objects.map = undefined;
    var player: objects.player = undefined;
    var state: gameState = gameState.titleScreen;
    var level: u8 = undefined;

    while (!exitGame and !rl.WindowShouldClose()) {
        rl.BeginDrawing();
        defer rl.EndDrawing();
        switch (state) {
            gameState.titleScreen => {
                rl.ClearBackground(rl.RAYWHITE);
                var playButton = objects.button{ .rect = rl.Rectangle{ .x = 100, .y = 200, .width = 700, .height = 100 }, .hovered = false, .text = "Play Game", .fontsize = 50 };
                var exitButton = objects.button{ .rect = rl.Rectangle{ .x = 100, .y = 325, .width = 700, .height = 100 }, .hovered = false, .text = "Exit Game", .fontsize = 50 };
                exitButton.render();
                playButton.render();
                if (playButton.getClicked()) {
                    level = 1;
                    map = game.initMap(loadLevel(level));
                    player = objects.player.init(map.spawnPos.x, map.spawnPos.y);
                    state = gameState.gameScreen;
                }
                if (exitButton.getClicked()) {
                    exitGame = true;
                }
            },
            gameState.gameScreen => {
                if (rl.IsKeyPressed(.KEY_ESCAPE)) state = gameState.pauseScreen;
                player.update(&map, &state);
                game.bounds(&player, &map, &state);
                game.draw(map, player);
            },
            gameState.deathScreen => {
                const backGroundBox = rl.Rectangle{ .x = 200, .y = 50, .width = 500, .height = 300 };
                rl.DrawRectangleRec(backGroundBox, rl.LIGHTGRAY);
                rl.DrawRectangleLinesEx(backGroundBox, 5, rl.GRAY);
                rl.DrawText("You Died", screenWidth / 2 - @divTrunc(rl.MeasureText("You Died", 75), 2), 100, 75, rl.BLACK);
                var titleButton = objects.button{
                    .rect = rl.Rectangle{ .x = 225, .y = 200, .width = 200, .height = 100 },
                    .text = "Title Screen",
                    .fontsize = 20,
                };
                var respawnButton = objects.button{
                    .rect = rl.Rectangle{ .x = 475, .y = 200, .width = 200, .height = 100 },
                    .text = "Respawn",
                    .fontsize = 20,
                };
                respawnButton.render();
                titleButton.render();
                if (respawnButton.getClicked()) {
                    player.rect.x = map.spawnPos.x;
                    player.rect.y = map.spawnPos.y;
                    state = gameState.gameScreen;
                }
                if (titleButton.getClicked()) {
                    state = gameState.titleScreen;
                }
            },
            gameState.pauseScreen => {
                const backGroundBox = rl.Rectangle{ .x = 200, .y = 50, .width = 500, .height = 300 };
                rl.DrawRectangleRec(backGroundBox, rl.LIGHTGRAY);
                rl.DrawRectangleLinesEx(backGroundBox, 5, rl.GRAY);
                rl.DrawText("Paused", screenWidth / 2 - @divTrunc(rl.MeasureText("Paused", 75), 2), 100, 75, rl.BLACK);
                var titleButton = objects.button{
                    .rect = rl.Rectangle{ .x = 225, .y = 200, .width = 200, .height = 100 },
                    .text = "Title Screen",
                    .fontsize = 20,
                };
                var unpauseButton = objects.button{
                    .rect = rl.Rectangle{ .x = 475, .y = 200, .width = 200, .height = 100 },
                    .text = "Resume",
                    .fontsize = 20,
                };
                unpauseButton.render();
                titleButton.render();
                if (unpauseButton.getClicked()) {
                    state = gameState.gameScreen;
                }
                if (titleButton.getClicked()) {
                    state = gameState.titleScreen;
                }
                if (rl.IsKeyPressed(.KEY_ESCAPE)) state = gameState.gameScreen;
            },
            gameState.levelBeatScreen => {
                const backGroundBox = rl.Rectangle{ .x = 150, .y = 50, .width = 550, .height = 300 };
                rl.DrawRectangleRec(backGroundBox, rl.LIGHTGRAY);
                rl.DrawRectangleLinesEx(backGroundBox, 5, rl.GRAY);
                rl.DrawText("Level Beat", screenWidth / 2 - @divTrunc(rl.MeasureText("Level Beat", 75), 2), 100, 75, rl.BLACK);
                var titleButton = objects.button{
                    .rect = rl.Rectangle{ .x = 175, .y = 200, .width = 150, .height = 100 },
                    .text = "Title Screen",
                    .fontsize = 19,
                };
                var replayButton = objects.button{
                    .rect = rl.Rectangle{ .x = 350, .y = 200, .width = 150, .height = 100 },
                    .text = "Replay Level",
                    .fontsize = 19,
                };
                var nextButton = objects.button{
                    .rect = rl.Rectangle{ .x = 525, .y = 200, .width = 150, .height = 100 },
                    .text = "Next Level",
                    .fontsize = 19,
                };
                titleButton.render();
                replayButton.render();
                nextButton.render();
                if (titleButton.getClicked()) {
                    state = gameState.titleScreen;
                }
                if (replayButton.getClicked()) {
                    map = game.initMap(loadLevel(level));
                    player = objects.player.init(map.spawnPos.x, map.spawnPos.y);
                    state = gameState.gameScreen;
                }
                if (nextButton.getClicked()) {
                    level += 1;
                    map = game.initMap(loadLevel(level));
                    player = objects.player.init(map.spawnPos.x, map.spawnPos.y);
                    state = gameState.gameScreen;
                }
            },
        }
    }
}
pub fn loadLevel(toLoad: u8) levels.levelData {
    return (switch (toLoad) {
        1 => level1.x1y1,
        else => levels.blank,
    });
}
