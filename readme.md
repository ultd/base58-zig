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
   +   exe.root_module.addImport("base58-zig", base58_module);
       b.installArtifact(exe);

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
<summary><code>encodeAlloc</code> - Encodes a `[]u8` into an alloc'ed base58 encoded string.</summary>

**Example**

```zig
const std = @import("std");
const base58 = @import("base58-zig");

const allocator = std.heap.page_allocator;

var someBytes = [4]u8{ 10, 20, 30, 40 };

pub fn main() !void {
    const encoder = base58.Encoder.init(.{});
    var encodedStr = try encoder.encodeAlloc(allocator, &someBytes);
    defer allocator.free(encodedStr);
    std.log.debug("encoded val: {s}", .{encodedStr});
}
```

</details>

<details>
<summary><code>encode</code> - Base58 Encodes a `[]u8` into an `dest` buffer passed and returns bytes written to buffer.</summary>

<br/>
The `dest` buffer written to needs to be properly sized. Base58 encoding is a variable length encoder therefore you should allocate extra and then resize if needed afterwards. Below is an example.
<br/>
<br/>

**Example**

```zig
const std = @import("std");
const base58 = @import("base58-zig");

const allocator = std.heap.page_allocator;

var someBytes = [4]u8{ 10, 20, 30, 40 };

pub fn main() !void {
    const encoder = base58.Encoder.init(.{});

    // allocate someBytes.len * 2 []u8
    var dest = allocator.alloc(u8, someBytes.len * 2);

    var size = try encoder.encode(&someBytes, dest);
    if(dest != size) {
        dest = allocator.realloc(dest, size);
    }

    defer allocator.free(dest);
    std.log.debug("encoded val: {s}", .{dest});
}
```

</details>

<details>
<summary><code>decodeAlloc</code> - Decodes a base58 encoded string into a alloc'ed `[]u8` and returns it.</summary>

**Example**

```zig
const std = @import("std");
const base58 = @import("base58-zig");

const allocator = std.heap.page_allocator;

var encodedStr: []const u8 = "4rL4RCWHz3iNCdCaveD8KcHfV9YWGsqSHFPo7X2zBNwa";

pub fn main() !void {
    const decoder = base58.Decoder.init(.{});
    var decodedBytes = try decoder.decodeAlloc(allocator, encodedStr);
    defer allocator.free(decodedBytes);
    std.log.debug("decoded bytes: {any}", .{decodedBytes});
}
```

</details>

<details>
<summary><code>decode</code> - Decodes a base58 encoded string into `dest` buffer and returns number of bytes written.</summary>

<br/>
The `dest` buffer written to needs to be properly sized. Base58 encoding is a variable length encoder therefore you should allocate same size buffer as encoded value and then resize, if needed, afterwards. Below is an example.
<br/>
<br/>

**Example**

```zig
const std = @import("std");
const base58 = @import("base58-zig");

const allocator = std.heap.page_allocator;

var encodedStr: []const u8 = "4rL4RCWHz3iNCdCaveD8KcHfV9YWGsqSHFPo7X2zBNwa";

pub fn main() !void {
    const decoder = base58.Decoder.init(.{});

    // allocate 1 * encodedStr.len buffer
    var dest = allocator.alloc(u8, encodedStr.len);

    var size = try decoder.decode(encodedStr, dest);
    if(dest.len != size){
        dest = allocator.realloc(dest, size);
    }

    defer allocator.free(dest);
    std.log.debug("decoded bytes: {any}", .{dest});
}
```

</details>

<details>
<summary><code>Alphabet</code> - create a custom alphabet set to pass to encoder/decoder`.</summary>

**Example**

```zig
const std = @import("std");
const base58 = @import("base58-zig");

const allocator = std.heap.page_allocator;

var alpha = base58.Alphabet.new(.{
.alphabet = [58]u8{...}. // custom alphabets
});

pub fn main() !void {
    const encoder = base58.Encoder.init(.{ alphabet = alpha });
    var encodedStr = try encoder.encodeAlloc(allocator, &someBytes);
    defer allocator.free(encodedStr);
    std.log.debug("encoded val: {s}", .{encodedStr});
}
```

</details>
