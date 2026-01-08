const std = @import("std");
const expect = @import("zspec").expect;
const zig_utils = @import("zig_utils");
const zon = zig_utils.zon;

pub const ZonCoercionSpec = struct {
    pub const coerceValue = struct {
        test "coerces simple struct with all fields" {
            const Target = struct { x: i32, y: i32 };
            const result = zon.coerceValue(Target, .{ .x = 10, .y = 20 });

            try expect.equal(result.x, 10);
            try expect.equal(result.y, 20);
        }

        test "coerces nested struct" {
            const Inner = struct { value: i32 };
            const Outer = struct { inner: Inner, name: []const u8 };
            const result = zon.coerceValue(Outer, .{ .inner = .{ .value = 42 }, .name = "test" });

            try expect.equal(result.inner.value, 42);
        }

        test "coerces union with enum literal" {
            const State = union(enum) { idle, running: u32 };
            const result = zon.coerceValue(State, .idle);

            try expect.toBeTrue(result == .idle);
        }

        test "coerces union with payload" {
            const Shape = union(enum) { circle: struct { radius: f32 }, rect: struct { w: f32, h: f32 } };
            const result = zon.coerceValue(Shape, .{ .circle = .{ .radius = 5.0 } });

            try expect.equal(result.circle.radius, 5.0);
        }
    };

    pub const tupleToSlice = struct {
        test "converts tuple to slice" {
            const slice = zon.tupleToSlice(i32, .{ 1, 2, 3 });

            try expect.equal(slice.len, 3);
            try expect.equal(slice[0], 1);
            try expect.equal(slice[1], 2);
            try expect.equal(slice[2], 3);
        }
    };

    pub const buildStruct = struct {
        test "builds struct with defaults" {
            const Config = struct { width: i32 = 800, height: i32 = 600, title: []const u8 };
            const result = zon.buildStruct(Config, .{ .title = "Test" });

            try expect.equal(result.width, 800);
            try expect.equal(result.height, 600);
        }
    };

    pub const mergeStructs = struct {
        test "merges structs with override values" {
            const base = .{ .x = 10, .y = 20, .color = "red" };
            const overrides = .{ .color = "blue" };
            const result = zon.mergeStructs(base, overrides);

            try expect.equal(result.x, 10);
            try expect.toBeTrue(std.mem.eql(u8, result.color, "blue"));
        }
    };
};
