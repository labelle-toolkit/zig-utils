// zig-utils - Standalone math utilities for Zig
// No external dependencies, only std

pub const vector = @import("vector.zig");
pub const Position = vector.Position;
pub const PositionI = vector.PositionI;

pub const quad_tree = @import("quad_tree.zig");
pub const QuadTree = quad_tree.QuadTree;
pub const QuadTreeNode = quad_tree.QuadTreeNode;
pub const Rectangle = quad_tree.Rectangle;

// Backwards compatibility alias (deprecated)
pub const Vector2 = Position;
