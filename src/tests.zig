const std = @import("std");
const Encoder = @import("./encode.zig").Encoder;
const Decoder = @import("./decode.zig").Decoder;
const Alphabet = @import("./alphabet.zig").Alphabet;
const testing = std.testing;

test "should encodeAlloc value correctly" {
    testing.log_level = std.log.Level.debug;

    var source = [32]u8{
        57,  54,  18,  6,   106, 202, 13,  245, 224, 235, 33,  252, 254,
        251, 161, 17,  248, 108, 25,  214, 169, 154, 91,  101, 17,  121,
        235, 82,  175, 197, 144, 145,
    };

    const encoder = Encoder.init(.{});
    var encodedVal = try encoder.encodeAlloc(
        testing.allocator,
        source[0..],
    );
    defer testing.allocator.free(encodedVal);

    try testing.expect(std.mem.eql(u8, encodedVal, "4rL4RCWHz3iNCdCaveD8KcHfV9YWGsqSHFPo7X2zBNwa"));
}

test "should decodeAlloc value correctly" {
    testing.log_level = std.log.Level.debug;

    var original = [32]u8{
        57,  54,  18,  6,   106, 202, 13,  245, 224, 235, 33,  252, 254,
        251, 161, 17,  248, 108, 25,  214, 169, 154, 91,  101, 17,  121,
        235, 82,  175, 197, 144, 145,
    };

    var encodedVal = "4rL4RCWHz3iNCdCaveD8KcHfV9YWGsqSHFPo7X2zBNwa";

    const decoder = Decoder.init(.{});
    var decodedVal = try decoder.decodeAlloc(testing.allocator, encodedVal);
    defer testing.allocator.free(decodedVal);

    try testing.expect(std.mem.eql(u8, decodedVal, &original));
}

test "strings as bytes encodeAlloc/decodeAlloc correctly" {
    testing.log_level = std.log.Level.debug;

    var someMsg: [12]u8 = [12]u8{ 'H', 'e', 'l', 'l', 'o', ',', ' ', 'W', 'o', 'r', 'l', 'd' };
    const encoder = Encoder.init(.{});

    var encodedVal = try encoder.encodeAlloc(
        testing.allocator,
        someMsg[0..],
    );
    defer testing.allocator.free(encodedVal);

    const decoder = Decoder.init(.{});

    var decodedVal = try decoder.decodeAlloc(testing.allocator, encodedVal[0..]);
    defer testing.allocator.free(decodedVal);

    try testing.expect(std.mem.eql(u8, decodedVal, &someMsg));
}

test "should encodeAlloc leading 0s slice properly" {
    testing.log_level = std.log.Level.debug;

    var slice = [10]u8{ 0, 0, 13, 4, 5, 6, 3, 23, 64, 75 };

    const encoder = Encoder.init(.{});
    var encodedVal = try encoder.encodeAlloc(
        testing.allocator,
        &slice,
    );
    defer testing.allocator.free(encodedVal);

    const decoder = Decoder.init(.{});

    var decodedVal = try decoder.decodeAlloc(testing.allocator, encodedVal);
    defer testing.allocator.free(decodedVal);

    try testing.expect(std.mem.eql(u8, decodedVal, &slice));
}

test "should encodeAlloc single byte slice" {
    testing.log_level = std.log.Level.debug;

    var slice = [1]u8{255};

    const encoder = Encoder.init(.{});
    var encodedVal = try encoder.encodeAlloc(
        testing.allocator,
        &slice,
    );
    defer testing.allocator.free(encodedVal);

    const decoder = Decoder.init(.{});
    var decodedVal = try decoder.decodeAlloc(testing.allocator, encodedVal);
    defer testing.allocator.free(decodedVal);

    try testing.expect(std.mem.eql(u8, decodedVal, &slice));
}

test "should encodeAlloc variable slice sizes" {
    testing.log_level = std.log.Level.debug;

    var iters: usize = 1000;
    var i: usize = 0;
    const encoder = Encoder.init(.{});
    const decoder = Decoder.init(.{});

    while (i < iters) : (i += 1) {
        var slice = try generateRandomByteSlice(testing.allocator, i, 256);
        defer testing.allocator.free(slice);
        var encodedVal = try encoder.encodeAlloc(
            testing.allocator,
            slice,
        );
        defer testing.allocator.free(encodedVal);

        var decodedVal = try decoder.decodeAlloc(testing.allocator, encodedVal);
        defer testing.allocator.free(decodedVal);

        try testing.expect(std.mem.eql(u8, decodedVal, slice));
    }
}

test "should encode and decode appropriately " {
    testing.log_level = std.log.Level.debug;

    var iters: usize = 1000;
    var i: usize = 0;
    const encoder = Encoder.init(.{});
    const decoder = Decoder.init(.{});

    while (i < iters) : (i += 1) {
        var originalSlice = try generateRandomByteSlice(testing.allocator, i, 256);
        defer testing.allocator.free(originalSlice);

        var destEncoded = try testing.allocator.alloc(u8, originalSlice.len * 2);
        var encodeWritten = try encoder.encode(originalSlice, destEncoded);
        if (encodeWritten < destEncoded.len) {
            destEncoded = try testing.allocator.realloc(destEncoded, encodeWritten);
        }
        defer testing.allocator.free(destEncoded);

        var destDecoded = try testing.allocator.alloc(u8, originalSlice.len);
        var decodeWriten = try decoder.decode(destEncoded, destDecoded);
        if (decodeWriten < destDecoded.len) {
            destDecoded = try testing.allocator.realloc(destDecoded, decodeWriten);
        }
        defer testing.allocator.free(destDecoded);

        try testing.expect(std.mem.eql(u8, destDecoded, originalSlice));
    }
}

fn generateRandomByteSlice(allocator: std.mem.Allocator, seed: usize, maxLength: usize) ![]u8 {
    var rng = std.rand.DefaultPrng.init(@intCast(u64, std.time.timestamp() * @intCast(i64, seed)));
    const length = rng.random().uintAtMost(usize, maxLength);
    var slice = try allocator.alloc(u8, length);
    rng.random().bytes(slice);
    return slice;
}
