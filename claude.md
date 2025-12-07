# zig-utils

Standalone math utilities library for Zig. Part of the labelle-toolkit.

## Project Structure

```
src/
  root.zig       - Main module exports
  vector.zig     - Position and PositionI types
  quad_tree.zig  - QuadTree spatial partitioning
tests/
  root.zig       - Test entry point
  vector_test.zig    - Position/PositionI tests
  quad_tree_test.zig - QuadTree tests
```

## Key Types

- `Position` (f32) - 2D vector for positions, directions, velocities
- `PositionI` (i32) - Integer position for pixel-perfect work
- `QuadTree` - Spatial index for efficient 2D queries
- `Rectangle` - AABB for bounds and collision

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

## Related

- labelle-engine - Game engine using these utilities
- labelle-gfx - Graphics library
