// zig-utils - Standalone math utilities for Zig
// No external dependencies, only std

pub const vector = @import("vector.zig");
pub const Vector2 = vector.Vector2;

// Convenience alias for Position (same as Vector2)
pub const Position = Vector2;

test {
    @import("std").testing.refAllDecls(@This());
}
