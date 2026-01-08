const std = @import("std");
const expect = @import("zspec").expect;
const zig_utils = @import("zig_utils");
const heuristics = zig_utils.heuristics;
const Position = zig_utils.Position;

pub const HeuristicsSpec = struct {
    pub const euclidean = struct {
        test "calculates euclidean distance" {
            const a = Position{ .x = 0, .y = 0 };
            const b = Position{ .x = 3, .y = 4 };

            const result = heuristics.euclidean(a, b);

            try expect.toBeTrue(@abs(result - 5.0) < 0.001);
        }
    };

    pub const manhattan = struct {
        test "calculates manhattan distance" {
            const a = Position{ .x = 0, .y = 0 };
            const b = Position{ .x = 3, .y = 4 };

            const result = heuristics.manhattan(a, b);

            try expect.toBeTrue(@abs(result - 7.0) < 0.001);
        }
    };

    pub const chebyshev = struct {
        test "calculates chebyshev distance" {
            const a = Position{ .x = 0, .y = 0 };
            const b = Position{ .x = 3, .y = 4 };

            const result = heuristics.chebyshev(a, b);

            try expect.toBeTrue(@abs(result - 4.0) < 0.001);
        }
    };

    pub const octile = struct {
        test "calculates octile distance" {
            const a = Position{ .x = 0, .y = 0 };
            const b = Position{ .x = 3, .y = 4 };

            const result = heuristics.octile(a, b);
            // 4 + (sqrt(2)-1) * 3 = 4 + 0.414 * 3 = 5.243

            try expect.toBeTrue(@abs(result - 5.243) < 0.01);
        }
    };

    pub const calculate_with_enum = struct {
        test "calculates using heuristic enum" {
            const a = Position{ .x = 0, .y = 0 };
            const b = Position{ .x = 3, .y = 4 };

            try expect.toBeTrue(@abs(heuristics.calculate(.euclidean, a, b) - 5.0) < 0.001);
            try expect.toBeTrue(@abs(heuristics.calculate(.manhattan, a, b) - 7.0) < 0.001);
            try expect.toBeTrue(@abs(heuristics.calculate(.zero, a, b) - 0.0) < 0.001);
        }
    };
};
