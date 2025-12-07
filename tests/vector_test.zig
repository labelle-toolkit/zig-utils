const std = @import("std");
const expect = @import("zspec").expect;
const zig_utils = @import("zig_utils");
const Position = zig_utils.Position;

pub const PositionSpec = struct {
    pub const add = struct {
        test "returns sum of two positions" {
            const a = Position{ .x = 1, .y = 2 };
            const b = Position{ .x = 3, .y = 4 };
            const result = a.add(b);

            try expect.equal(result.x, 4);
            try expect.equal(result.y, 6);
        }
    };

    pub const distance = struct {
        test "returns euclidean distance between two positions" {
            const a = Position{ .x = 0, .y = 0 };
            const b = Position{ .x = 3, .y = 4 };

            try expect.equal(a.distance(b), 5);
        }
    };

    pub const normalize = struct {
        test "returns unit position with length 1" {
            const v = Position{ .x = 3, .y = 4 };
            const n = v.normalize();

            try expect.equal(n.length(), 1);
        }
    };

    pub const sub = struct {
        test "returns difference of two positions" {
            const a = Position{ .x = 5, .y = 7 };
            const b = Position{ .x = 2, .y = 3 };
            const result = a.sub(b);

            try expect.equal(result.x, 3);
            try expect.equal(result.y, 4);
        }
    };

    pub const scale = struct {
        test "multiplies position by scalar" {
            const v = Position{ .x = 2, .y = 3 };
            const result = v.scale(2);

            try expect.equal(result.x, 4);
            try expect.equal(result.y, 6);
        }
    };

    pub const dot = struct {
        test "returns dot product of two positions" {
            const a = Position{ .x = 1, .y = 2 };
            const b = Position{ .x = 3, .y = 4 };

            try expect.equal(a.dot(b), 11);
        }
    };

    pub const length = struct {
        test "returns magnitude of position" {
            const v = Position{ .x = 3, .y = 4 };

            try expect.equal(v.length(), 5);
        }
    };
};
