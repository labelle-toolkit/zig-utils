# zig-utils

Standalone math utilities for Zig. Part of the [labelle-toolkit](https://github.com/labelle-toolkit).

## Features

- **Position** - 2D vector/position type with comprehensive math operations
- **PositionI** - Integer position for pixel-perfect positioning
- **QuadTree** - Generic spatial partitioning with Position-based queries
- **SweepAndPrune** - Broad-phase collision detection for AABBs
- **Rectangle** - Axis-aligned bounding box with intersection/containment tests

No external dependencies beyond the Zig standard library.

## Installation

Add to your `build.zig.zon`:

```zig
.dependencies = .{
    .zig_utils = .{
        .url = "https://github.com/labelle-toolkit/zig-utils/archive/refs/tags/v0.4.0.tar.gz",
        .hash = "...",  // Run `zig build` to get the hash
    },
},
```

Then in your `build.zig`:

```zig
const zig_utils = b.dependency("zig_utils", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("zig_utils", zig_utils.module("zig_utils"));
```

## Usage

### Position

```zig
const zig_utils = @import("zig_utils");
const Position = zig_utils.Position;

const a = Position{ .x = 1, .y = 2 };
const b = Position{ .x = 3, .y = 4 };

const sum = a.add(b);           // Position{4, 6}
const dist = a.distance(b);     // 2.828...
const normalized = b.normalize(); // unit vector
const rotated = a.rotate(std.math.pi / 2); // 90 degrees
```

### PositionI (Integer)

```zig
const PositionI = zig_utils.PositionI;

const pixel = PositionI{ .x = 100, .y = 200 };
const float_pos = pixel.toPosition();  // Convert to Position
const back = PositionI.fromPosition(float_pos);  // Rounds to nearest
```

### QuadTree

Generic spatial partitioning with Position-based API:

```zig
const QuadTree = zig_utils.QuadTree;
const EntityPoint = zig_utils.EntityPoint;

// Create tree with u32 entity IDs
const QT = QuadTree(u32);
const Point = EntityPoint(u32);

var qt = try QT.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
defer qt.deinit();

// Insert using Position
_ = qt.insert(Point.init(1, 10, 10));
_ = qt.insert(Point.fromPosition(2, Position{ .x = 50, .y = 50 }));

// Query rectangle
var results: std.ArrayListUnmanaged(Point) = .empty;
defer results.deinit(allocator);
try qt.queryRect(.{ .x = 0, .y = 0, .width = 30, .height = 30 }, &results);

// Query radius
try qt.queryRadius(Position{ .x = 10, .y = 10 }, 15, &results);

// Find nearest
const nearest = qt.queryNearest(Position{ .x = 12, .y = 12 }, 100);

// Update and remove
_ = qt.update(1, Position{ .x = 20, .y = 20 });
_ = qt.remove(1);
```

### Sweep and Prune

Efficient broad-phase collision detection:

```zig
const SweepAndPrune = zig_utils.SweepAndPrune;

const SAP = SweepAndPrune(u32);
var sap = SAP.init(allocator);
defer sap.deinit();

// Add entities with position and half-extents
try sap.add(1, Position{ .x = 0, .y = 0 }, 10, 10);
try sap.add(2, Position{ .x = 5, .y = 5 }, 10, 10);
try sap.add(3, Position{ .x = 100, .y = 100 }, 10, 10);

// Find all collision pairs
var pairs: std.ArrayListUnmanaged(SAP.Pair) = .empty;
defer pairs.deinit(allocator);
try sap.findCollisions(&pairs);
// pairs contains (1, 2) since they overlap

// Update positions
sap.updatePosition(1, Position{ .x = 50, .y = 50 });

// Query by region
var in_region: std.ArrayListUnmanaged(u32) = .empty;
try sap.queryRect(Position{ .x = 0, .y = 0 }, 30, 30, &in_region);
try sap.queryRadius(Position{ .x = 0, .y = 0 }, 20, &in_region);
```

## API Reference

### Position (f32)

| Method | Description |
|--------|-------------|
| `add`, `sub`, `mul`, `div` | Vector arithmetic |
| `scale(scalar)` | Multiply by scalar |
| `length`, `lengthSquared` | Magnitude |
| `distance`, `distanceSquared` | Distance to another position |
| `normalize` | Unit vector |
| `dot`, `cross` | Dot and cross product |
| `lerp(other, t)` | Linear interpolation |
| `rotate(radians)` | Rotation |
| `angle`, `angleTo` | Angle in radians |
| `clamp`, `clampLength` | Constrain values |
| `abs`, `floor`, `ceil`, `round` | Component-wise operations |
| `eql`, `eqlApprox` | Equality tests |

### PositionI (i32)

| Method | Description |
|--------|-------------|
| `add`, `sub`, `mul` | Integer arithmetic |
| `scale(scalar)` | Multiply by scalar |
| `negate` | Negate components |
| `lengthSquared`, `distanceSquared` | Returns i64 to avoid overflow |
| `toPosition` | Convert to Position (f32) |
| `fromPosition` | Convert from Position with rounding |
| `eql` | Equality test |

### QuadTree(T)

Generic over ID type. Uses flat array storage for cache efficiency.

| Method | Description |
|--------|-------------|
| `init(allocator, bounds)` | Create a new QuadTree |
| `deinit()` | Free all memory |
| `insert(point)` | Add an entity point |
| `remove(id)` | Remove by ID |
| `update(id, new_pos)` | Update entity position |
| `queryRect(range, buffer)` | Find points in rectangle |
| `queryRadius(center, radius, buffer)` | Find points in radius |
| `queryNearest(pos, max_distance)` | Find closest point |
| `hasPointInRect(range)` | Check if any point exists |
| `count()` | Total number of points |
| `reset()` | Clear keeping boundaries |

### SweepAndPrune(T)

Generic over ID type. O(n log n) broad-phase collision detection.

| Method | Description |
|--------|-------------|
| `init(allocator)` | Create a new system |
| `deinit()` | Free all memory |
| `add(id, pos, half_w, half_h)` | Add an entity |
| `remove(id)` | Remove by ID |
| `updatePosition(id, new_pos)` | Update entity position |
| `findCollisions(pairs)` | Find all overlapping pairs |
| `queryRect(center, half_w, half_h, results)` | Find entities in AABB |
| `queryRadius(center, radius, results)` | Find entities in radius |
| `clear()` | Remove all entities |

### Rectangle

| Method | Description |
|--------|-------------|
| `fromPosition(pos, w, h)` | Create from position |
| `centered(pos, w, h)` | Create centered on position |
| `center()` | Get center position |
| `position()` | Get top-left position |
| `contains(x, y)` | Point containment test |
| `containsPosition(pos)` | Position containment test |
| `intersects(other)` | AABB intersection test |

## Running Tests

```bash
zig build test
```

## License

MIT
