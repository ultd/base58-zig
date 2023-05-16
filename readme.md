<br/>

<p align="center">
  <h1>&nbsp;🌀 &nbsp;&nbsp;Base58-zig</h1>
    <br/>
    <br/>
  <a href="https://github.com/ultd/base58-zig/releases/latest"><img alt="Version" src="https://img.shields.io/github/v/release/ultd/base58-zig?include_prereleases&label=version"></a>
  <a href="https://github.com/ultd/base58-zig/actions/workflows/test.yml"><img alt="Build status" src="https://img.shields.io/github/actions/workflow/status/ultd/base58-zig/test.yml?branch=main" /></a>
  <a href="https://ziglang.org/download"><img alt="Zig" src="https://img.shields.io/badge/zig-master-green.svg"></a>
  <a href="https://github.com/ultd/base58-zig/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-blue"></a>
</p>
<br/>

## Overview

_base58-zig_ is encoder/decoder library written in Zig.

## Installation

### Manual

1. Declare Base58-zig as a dependency in `build.zig.zon`:

   ```diff
   .{
       .name = "my-project",
       .version = "1.0.0",
       .dependencies = .{
   +       .@"base58-zig" = .{
   +           .url = "https://github.com/ultd/base58-zig/archive/<COMMIT>.tar.gz",
   +       },
       },
   }
   ```

2. Expose Base58-zig as a module in `build.zig`:

   ```diff
   const std = @import("std");

   pub fn build(b: *std.Build) void {
       const target = b.standardTargetOptions(.{});
       const optimize = b.standardOptimizeOption(.{});

   +   const opts = .{ .target = target, .optimize = optimize };
   +   const base58_module = b.dependency("base58-zig", opts).module("base58-zig");

       const exe = b.addExecutable(.{
           .name = "test",
           .root_source_file = .{ .path = "src/main.zig" },
           .target = target,
           .optimize = optimize,
       });
   +   exe.addModule("base58-zig", base58_module);
       exe.install();

       ...
   }
   ```

3. Obtain Base58-zig's package hash:

   ```
   $ zig build
   my-project/build.zig.zon:6:20: error: url field is missing corresponding hash field
           .url = "https://github.com/ultd/base58-zig/archive/<COMMIT>.tar.gz",
                  ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   note: expected .hash = "<HASH>",
   ```

4. Update `build.zig.zon` with hash value:

   ```diff
   .{
       .name = "my-project",
       .version = "1.0.0",
       .dependencies = .{
           .@"base58-zig" = .{
               .url = "https://github.com/ultd/base58-zig/archive/<COMMIT>.tar.gz",
   +           .hash = "<HASH>",
           },
       },
   }
   ```

### API Reference

<details>
<summary><code>Encoder</code> - Encodes a `[]u8` into a base58 encoded string.</summary>

**Example**

```zig
const std = @import("std");
const base58 = @import("base58-zig");

const allocator = std.heap.page_allocator;

var someBytes = [4]u8{ 10, 20, 30, 40 };

pub fn main() !void {
    var encoder = base58.Encoder.init(allocator, .{});
    var encodedStr = try encoder.encode(allocator, &someBytes);
    std.log.debug("encoded val: {s}", .{encodedStr});
}
```

</details>

<details>
<summary><code>Decoder</code> - Decodes a base58 encoded string into a `[]u8`.</summary>

**Example**

```zig
const std = @import("std");
const base58 = @import("base58-zig");

const allocator = std.heap.page_allocator;

var encodedStr: []const u8 = "4rL4RCWHz3iNCdCaveD8KcHfV9YWGsqSHFPo7X2zBNwa";

pub fn main() !void {
    var decoder = base58.Decoder.init(allocator, .{});
    var decodedBytes = try decoder.decode(encodedStr);
    std.log.debug("decoded bytes: {any}", .{decodedBytes});
}
```

</details>

<details>
<summary><code>Custom Alphabet</code> - create a custom alphabet set to pass to encoder/decoder`.</summary>

**Example**

```zig
const std = @import("std");
const base58 = @import("base58-zig");

const allocator = std.heap.page_allocator;

var alpha = base58.Alphabet.new(.{
.alphabet = [58]u8{...}. // custom alphabets
});

pub fn main() !void {
    var encoder = base58.Encoder.init(allocator, .{ alphabet = alpha });
    var encodedStr = try encoder.encode(allocator, &someBytes);
    std.log.debug("encoded val: {s}", .{encodedStr});
}
```

</details>
