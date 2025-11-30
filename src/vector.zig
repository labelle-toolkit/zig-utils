// Vector2 - standalone vector math utilities for Zig
// No external dependencies, only std

const std = @import("std");

pub const Vector2 = struct {
    x: f32 = 0,
    y: f32 = 0,

    pub const zero = Vector2{ .x = 0, .y = 0 };
    pub const one = Vector2{ .x = 1, .y = 1 };

    pub fn add(self: Vector2, other: Vector2) Vector2 {
        return .{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn move(self: *Vector2, dx: f32, dy: f32) void {
        self.x += dx;
        self.y += dy;
    }

    pub fn sub(self: Vector2, other: Vector2) Vector2 {
        return .{ .x = self.x - other.x, .y = self.y - other.y };
    }

    pub fn scale(self: Vector2, scalar: f32) Vector2 {
        return .{ .x = self.x * scalar, .y = self.y * scalar };
    }

    pub fn mul(self: Vector2, other: Vector2) Vector2 {
        return .{ .x = self.x * other.x, .y = self.y * other.y };
    }

    pub fn div(self: Vector2, other: Vector2) Vector2 {
        return .{ .x = self.x / other.x, .y = self.y / other.y };
    }

    pub fn negate(self: Vector2) Vector2 {
        return .{ .x = -self.x, .y = -self.y };
    }

    pub fn length(self: Vector2) f32 {
        return @sqrt(self.x * self.x + self.y * self.y);
    }

    pub fn lengthSquared(self: Vector2) f32 {
        return self.x * self.x + self.y * self.y;
    }

    pub fn normalize(self: Vector2) Vector2 {
        const len = self.length();
        if (len == 0) return self;
        return self.scale(1.0 / len);
    }

    pub fn distance(self: Vector2, other: Vector2) f32 {
        return self.sub(other).length();
    }

    pub fn distanceSquared(self: Vector2, other: Vector2) f32 {
        return self.sub(other).lengthSquared();
    }

    pub fn dot(self: Vector2, other: Vector2) f32 {
        return self.x * other.x + self.y * other.y;
    }

    pub fn cross(self: Vector2, other: Vector2) f32 {
        return self.x * other.y - self.y * other.x;
    }

    pub fn lerp(self: Vector2, other: Vector2, t: f32) Vector2 {
        return .{
            .x = self.x + (other.x - self.x) * t,
            .y = self.y + (other.y - self.y) * t,
        };
    }

    pub fn rotate(self: Vector2, radians: f32) Vector2 {
        const cos_a = @cos(radians);
        const sin_a = @sin(radians);
        return .{
            .x = self.x * cos_a - self.y * sin_a,
            .y = self.x * sin_a + self.y * cos_a,
        };
    }

    pub fn perpendicular(self: Vector2) Vector2 {
        return .{ .x = -self.y, .y = self.x };
    }

    pub fn angle(self: Vector2) f32 {
        return std.math.atan2(self.y, self.x);
    }

    pub fn angleTo(self: Vector2, other: Vector2) f32 {
        return other.sub(self).angle();
    }

    pub fn clamp(self: Vector2, min: Vector2, max: Vector2) Vector2 {
        return .{
            .x = std.math.clamp(self.x, min.x, max.x),
            .y = std.math.clamp(self.y, min.y, max.y),
        };
    }

    pub fn clampLength(self: Vector2, min_len: f32, max_len: f32) Vector2 {
        const len = self.length();
        if (len == 0) return self;
        const clamped = std.math.clamp(len, min_len, max_len);
        return self.scale(clamped / len);
    }

    pub fn abs(self: Vector2) Vector2 {
        return .{ .x = @abs(self.x), .y = @abs(self.y) };
    }

    pub fn floor(self: Vector2) Vector2 {
        return .{ .x = @floor(self.x), .y = @floor(self.y) };
    }

    pub fn ceil(self: Vector2) Vector2 {
        return .{ .x = @ceil(self.x), .y = @ceil(self.y) };
    }

    pub fn round(self: Vector2) Vector2 {
        return .{ .x = @round(self.x), .y = @round(self.y) };
    }

    pub fn eql(self: Vector2, other: Vector2) bool {
        return self.x == other.x and self.y == other.y;
    }

    pub fn eqlApprox(self: Vector2, other: Vector2, epsilon: f32) bool {
        return @abs(self.x - other.x) <= epsilon and @abs(self.y - other.y) <= epsilon;
    }

    pub fn format(
        self: Vector2,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("Vector2({d:.2}, {d:.2})", .{ self.x, self.y });
    }
};
