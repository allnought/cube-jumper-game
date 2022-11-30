const rl = @import("raylib/raylib.zig");
const std = @import("std");
const levels = @import("levels.zig");
const main = @import("main.zig");

pub const button = struct {
    rect: rl.Rectangle,
    hovered: bool = false,
    text: [*:0]const u8,
    fontsize: i32,
    pub fn checkHover(self: *button) bool {
        if (rl.CheckCollisionPointRec(rl.Vector2{ .x = @intToFloat(f32, rl.GetMouseX()), .y = @intToFloat(f32, rl.GetMouseY()) }, self.rect)) return true else return false;
    }
    pub fn getClicked(self: *button) bool {
        if (self.checkHover()) {
            self.hovered = true;
            if (rl.IsMouseButtonPressed(.MOUSE_BUTTON_LEFT) or rl.IsKeyPressed(.KEY_ENTER)) {
                return true;
            } else {
                return false;
            }
        } else {
            self.hovered = false;
            return false;
        }
    }
    pub fn render(self: *button) void {
        rl.DrawRectangleRec(self.rect, rl.GRAY);
        self.hovered = self.checkHover();
        rl.DrawRectangleLinesEx(self.rect, 5, switch (self.hovered) {
            false => rl.BLACK,
            true => rl.SKYBLUE,
        });
        rl.DrawText(self.text, @floatToInt(i32, self.rect.x) + @divTrunc(@floatToInt(i32, self.rect.width), 2) - @divTrunc(rl.MeasureText(self.text, self.fontsize), 2), @floatToInt(i32, self.rect.y) + @divTrunc(@floatToInt(i32, self.rect.height), 2) - @divTrunc(self.fontsize, 2), self.fontsize, rl.BLACK);
    }
};

pub const map = struct { grid: []tile, spawnPos: rl.Vector2, id: u8 = undefined };

pub const tile = struct {
    rect: rl.Rectangle,
    type: u8,
};

pub const player = struct {
    rect: rl.Rectangle,
    velocity: rl.Vector2,
    grounded: bool,
    airJumped: bool,
    jumpHeight: f32 = 13,
    walkSpeed: f32 = 4,
    gravity: f32 = 1,
    pub fn init(x: f32, y: f32) player {
        return player{
            .rect = rl.Rectangle{
                .x = x,
                .y = y,
                .width = 30,
                .height = 60,
            },
            .velocity = rl.Vector2{ .x = 0, .y = 0 },
            .grounded = false,
            .airJumped = false,
        };
    }
    pub fn colCheck(self: *player, obstacles: *map, x: f32, y: f32) tile {
        var fallbackRect = tile{ .rect = undefined, .type = 0 };
        for (obstacles.grid) |obstacle, index| {
            if (rl.CheckCollisionRecs(obstacle.rect, rl.Rectangle{
                .x = self.rect.x + x,
                .y = self.rect.y + y,
                .width = self.rect.width,
                .height = self.rect.height,
            })) {
                if (obstacle.type == 1) {
                    self.jumpHeight = 13;
                    self.walkSpeed = 4;
                    return obstacles.grid[index];
                } else {
                    if (obstacle.type != 2) {
                        fallbackRect.rect = obstacle.rect;
                        fallbackRect.type = obstacle.type;
                    } else if (fallbackRect.type == 0) {
                        fallbackRect.rect = obstacle.rect;
                        fallbackRect.type = obstacle.type;
                    }
                }
            }
        }
        return fallbackRect;
    }
    pub fn update(self: *player, obstacles: *map, state: *main.gameState) void {
        input(self);
        move(self, obstacles, state);
    }

    fn input(self: *player) void {
        if (rl.IsKeyPressed(.KEY_UP)) {
            if (self.grounded) {
                self.velocity.y = -self.jumpHeight * self.gravity;
            } else if (!self.airJumped) {
                self.velocity.y = -self.jumpHeight * self.gravity;
                self.airJumped = true;
            }
        }
        if (rl.IsKeyDown(.KEY_RIGHT)) {
            self.velocity.x = self.walkSpeed;
        } else if (rl.IsKeyDown(.KEY_LEFT)) {
            self.velocity.x = -self.walkSpeed;
        } else {
            self.velocity.x = 0;
        }
    }

    fn move(self: *player, obstacles: *map, state: *main.gameState) void {
        var lastCol = self.colCheck(obstacles, 0, self.gravity);
        if (doesCollide(lastCol.type)) {
            self.grounded = true;
            self.airJumped = false;
            tileInteract(self, lastCol.type, state);
        } else {
            self.velocity.y += self.gravity;
            self.grounded = false;
        }
        lastCol = self.colCheck(obstacles, self.velocity.x, 0);
        if (!doesCollide(lastCol.type)) {
            self.rect.x += self.velocity.x;
            tileInteract(self, lastCol.type, state);
        } else {
            if (self.velocity.x > 0) {
                self.rect.x = lastCol.rect.x - self.rect.width;
            } else {
                self.rect.x = lastCol.rect.x + lastCol.rect.width;
            }
            self.velocity.x = 0;
        }
        lastCol = self.colCheck(obstacles, 0, self.velocity.y);
        if (!doesCollide(lastCol.type)) {
            self.rect.y += self.velocity.y;
            tileInteract(self, lastCol.type, state);
        } else {
            if (self.velocity.y > 0) {
                self.rect.y = lastCol.rect.y - self.rect.height;
            } else {
                self.rect.y = lastCol.rect.y + lastCol.rect.height;
            }
            self.velocity.y = 0;
        }
    }
    pub fn die(self: *player, state: *main.gameState) void {
        state.* = main.gameState.deathScreen;
        self.velocity.x = 0;
        self.velocity.y = 0;
        self.gravity = 1;
    }
    fn tileInteract(self: *player, collideType: u8, state: *main.gameState) void {
        switch (collideType) {
            2 => self.die(state),
            3 => self.jumpHeight = 20,
            4 => self.walkSpeed = 10,
            5 => {
                self.jumpHeight = 20;
                self.walkSpeed = 10;
            },
            6 => {
                self.velocity.y = -16;
                self.airJumped = false;
            },
            7 => self.gravity = -self.gravity,
            8 => self.airJumped = false,
            9 => state.* = main.gameState.levelBeatScreen,
            else => _ = 0,
        }
    }
    fn doesCollide(typic: u8) bool {
        return switch (typic) {
            0 => false,
            1 => true,
            2 => false,
            3 => true,
            4 => true,
            5 => true,
            6 => true,
            7 => true,
            8 => false,
            else => false,
        };
    }
};
