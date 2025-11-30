// zig-utils - Standalone math utilities for Zig
// No external dependencies, only std

pub const vector = @import("vector.zig");
pub const Vector2 = vector.Vector2;

pub const quad_tree = @import("quad_tree.zig");
pub const QuadTree = quad_tree.QuadTree;
pub const QuadTreeNode = quad_tree.QuadTreeNode;
pub const Rectangle = quad_tree.Rectangle;

// Convenience alias for Position (same as Vector2)
pub const Position = Vector2;

test {
    @import("std").testing.refAllDecls(@This());
}
