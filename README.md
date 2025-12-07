# zig-utils

Standalone math utilities for Zig. Part of the [labelle-toolkit](https://github.com/labelle-toolkit).

## Features

- **Position** - 2D vector/position type with comprehensive math operations
- **PositionI** - Integer position for pixel-perfect positioning
- **QuadTree** - Spatial partitioning data structure for efficient 2D queries
- **Rectangle** - Axis-aligned bounding box with intersection/containment tests

No external dependencies beyond the Zig standard library.

## Installation

Add to your `build.zig.zon`:

```zig
.dependencies = .{
    .zig_utils = .{
        .url = "https://github.com/labelle-toolkit/zig-utils/archive/refs/tags/v0.3.0.tar.gz",
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

```zig
const QuadTree = zig_utils.QuadTree;
const Rectangle = zig_utils.Rectangle;

var qt = QuadTree.init(allocator, .{ .x = 0, .y = 0, .width = 100, .height = 100 });
defer qt.deinit();

try qt.insert(.{ .entity = 1, .x = 10, .y = 10 });
try qt.insert(.{ .entity = 2, .x = 50, .y = 50 });

// Query a region
var results: std.ArrayListUnmanaged(QuadTreeNode) = .empty;
defer results.deinit(allocator);
try qt.query(.{ .x = 0, .y = 0, .width = 30, .height = 30 }, &results, allocator);

// Find nearest
const nearest = qt.queryNearest(12, 12, 100);
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

### QuadTree

| Method | Description |
|--------|-------------|
| `init(allocator, bounds)` | Create a new QuadTree |
| `deinit()` | Free all memory |
| `insert(node)` | Add a node |
| `query(range, results, allocator)` | Find nodes in rectangle |
| `queryNearest(x, y, max_distance)` | Find closest node |
| `clear()` | Remove all nodes, keep structure |
| `count()` | Total number of nodes |

## Running Tests

```bash
zig build test
```

## License

MIT
