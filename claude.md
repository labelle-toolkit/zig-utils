# zig-utils

Standalone math utilities library for Zig. Part of the labelle-toolkit.

## Project Structure

```
src/
  root.zig                    - Main module exports
  vector.zig                  - Position and PositionI types
  quad_tree.zig               - QuadTree spatial partitioning
  sweep_and_prune.zig         - Sweep and Prune collision detection
  sparse_set.zig              - SparseSet O(1) key-value mapping
  z_index_buckets.zig         - ZIndexBuckets sorted storage by u8 key
  zon_coercion.zig            - Comptime ZON to struct conversion
  hook_dispatcher.zig         - Zero-overhead comptime event dispatcher
  floyd_warshall.zig          - Floyd-Warshall all-pairs shortest path
  floyd_warshall_optimized.zig - SIMD/parallel Floyd-Warshall
  a_star.zig                  - A* single-source pathfinding
  heuristics.zig              - Distance heuristics for A*
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
- `SparseSet(T)` - O(1) key-value mapping with cache-friendly iteration
- `ZIndexBuckets(T)` - Bucket-sorted storage by u8 key (256 buckets)
- `HookDispatcher` - Zero-overhead comptime event dispatcher
- `FloydWarshall` - All-pairs shortest path O(V³)
- `FloydWarshallOptimized` - SIMD/parallel Floyd-Warshall (5-16x faster)
- `AStar` - A* single-source pathfinding with heuristics
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

### SparseSet
- O(1) insert, remove, lookup (worst-case, not amortized)
- Cache-friendly dense array iteration
- Generic value type support
- Fixed memory based on max key range
- Ideal for entity -> component mappings

**Benchmark results (vs HashMap):**
| Operation | SparseSet | HashMap |
|-----------|-----------|---------|
| contains  | 0.76 ns   | 4.61 ns |

**Trade-off:** ~40KB memory for 10k max keys vs variable for HashMap

### ZIndexBuckets
- 256 buckets (one per u8 z-index level)
- O(1) insert, O(bucket_size) remove
- O(256 + n) ordered iteration
- Generic over item type T
- Optional custom equality via `eql` method

### ZON Coercion
- Comptime conversion of anonymous structs to typed structs
- Handles nested structs, optionals, slices, arrays
- Tagged union coercion from enum literals or structs
- Struct merging with override semantics
- Functions: `coerceValue`, `buildStruct`, `tupleToSlice`, `mergeStructs`

### HookDispatcher
- Zero-overhead comptime event dispatch
- Handlers resolved entirely at compile time
- No runtime overhead for missing handlers
- `MergeHooks` for composing multiple handler structs
- `EmptyDispatcher` for default no-op dispatching

### Graph Algorithms

**Floyd-Warshall** (all-pairs shortest path):
- O(V³) time, O(V²) space
- Best for dense graphs, frequent all-pairs queries
- Entity ID mapping support
- Optimized variant with SIMD (5-8x faster) and parallel (up to 16x)

**A\*** (single-source shortest path):
- Heuristic-guided best-first search
- Built-in heuristics: Euclidean, Manhattan, Chebyshev, Octile, Zero
- Custom heuristic function support
- Entity ID mapping for ECS integration
- Best for sparse graphs, real-time queries

**Heuristics**:
| Movement Type | Recommended |
|---------------|-------------|
| Any-angle | Euclidean |
| 4-directional | Manhattan |
| 8-dir equal cost | Chebyshev |
| 8-dir realistic | Octile |
| Unknown | Zero (Dijkstra) |

## Related

- labelle-pathfinding - Uses QuadTree for spatial queries
- labelle-engine - Game engine using these utilities
- labelle-gfx - Graphics library
