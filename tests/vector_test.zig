const std = @import("std");
const zig_utils = @import("zig_utils");
const Vector2 = zig_utils.Vector2;

test "Vector2.add" {
    const a = Vector2{ .x = 1, .y = 2 };
    const b = Vector2{ .x = 3, .y = 4 };
    const result = a.add(b);
    try std.testing.expectEqual(@as(f32, 4), result.x);
    try std.testing.expectEqual(@as(f32, 6), result.y);
}

test "Vector2.distance" {
    const a = Vector2{ .x = 0, .y = 0 };
    const b = Vector2{ .x = 3, .y = 4 };
    try std.testing.expectApproxEqAbs(@as(f32, 5), a.distance(b), 0.001);
}

test "Vector2.normalize" {
    const v = Vector2{ .x = 3, .y = 4 };
    const n = v.normalize();
    try std.testing.expectApproxEqAbs(@as(f32, 1), n.length(), 0.001);
}
