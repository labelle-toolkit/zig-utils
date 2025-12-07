// zig-utils - Standalone math utilities for Zig
// No external dependencies, only std

pub const vector = @import("vector.zig");
pub const Position = vector.Position;
pub const PositionI = vector.PositionI;

pub const quad_tree = @import("quad_tree.zig");
pub const QuadTree = quad_tree.QuadTree;
pub const EntityPoint = quad_tree.EntityPoint;
pub const Rectangle = quad_tree.Rectangle;

pub const sweep_and_prune = @import("sweep_and_prune.zig");
pub const SweepAndPrune = sweep_and_prune.SweepAndPrune;
pub const AABB = sweep_and_prune.AABB;
pub const CollisionPair = sweep_and_prune.CollisionPair;
pub const sweepAndPruneSimple = sweep_and_prune.sweepAndPrune;

// Backwards compatibility alias (deprecated)
pub const Vector2 = Position;
