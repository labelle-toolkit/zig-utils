# zig-utils

Standalone math utilities library for Zig. Part of the labelle-toolkit.

## Project Structure

```
src/
  root.zig           - Main module exports
  vector.zig         - Position and PositionI types
  quad_tree.zig      - QuadTree spatial partitioning (generic, Position-based)
  sweep_and_prune.zig - Sweep and Prune collision detection
tests/
  root.zig               - Test entry point
  vector_test.zig        - Position/PositionI tests
  quad_tree_test.zig     - QuadTree and Rectangle tests
  sweep_and_prune_test.zig - SweepAndPrune and AABB tests
```

## Key Types

- `Position` (f32) - 2D vector for positions, directions, velocities
- `PositionI` (i32) - Integer position for pixel-perfect work
- `QuadTree(T)` - Generic spatial index with Position-based queries
- `SweepAndPrune(T)` - Generic broad-phase collision detection
- `Rectangle` - AABB for bounds and collision
- `EntityPoint(T)` - Point with generic ID for QuadTree
- `AABB` - Axis-aligned bounding box for SweepAndPrune

## Testing

Uses [zspec](https://github.com/apotema/zspec) for BDD-style tests.

```bash
zig build test
```

## Conventions

- All types use method syntax (e.g., `pos.add(other)`)
- Immutable by default - methods return new values
- `*Squared` variants avoid sqrt for performance
- PositionI uses i64 for lengthSquared to prevent overflow
- QuadTree and SweepAndPrune are generic over ID type
- All spatial queries use Position type

## Spatial Data Structures

### QuadTree
- Flat array storage for cache efficiency
- Generic ID type support
- Position-based insert/query/update
- Radius and rectangle queries
- Nearest neighbor with pruning

### Sweep and Prune
- O(n log n) broad-phase collision
- Sort on X-axis, prune on Y
- Generic ID type support
- Position-based AABB queries

## Related

- labelle-pathfinding - Uses QuadTree for spatial queries
- labelle-engine - Game engine using these utilities
- labelle-gfx - Graphics library
