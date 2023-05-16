const std = @import("std");
const Encoder = @import("./encode.zig").Encoder;
const Decoder = @import("./decode.zig").Decoder;
const Alphabet = @import("./alphabet.zig").Alphabet;
const testing = std.testing;

test "should encode value correctly" {
    testing.log_level = std.log.Level.debug;

    var source = [32]u8{ 57, 54, 18, 6, 106, 202, 13, 245, 224, 235, 33, 252, 254, 251, 161, 17, 248, 108, 25, 214, 169, 154, 91, 101, 17, 121, 235, 82, 175, 197, 144, 145 };

    var encoder = Encoder.init(testing.allocator, .{});
    var encodedVal = try encoder.encode(
        source[0..],
    );
    defer testing.allocator.free(encodedVal);

    try testing.expect(std.mem.eql(u8, encodedVal, "4rL4RCWHz3iNCdCaveD8KcHfV9YWGsqSHFPo7X2zBNwa"));
}

test "should decode value correctly" {
    testing.log_level = std.log.Level.debug;

    var original = [32]u8{ 57, 54, 18, 6, 106, 202, 13, 245, 224, 235, 33, 252, 254, 251, 161, 17, 248, 108, 25, 214, 169, 154, 91, 101, 17, 121, 235, 82, 175, 197, 144, 145 };

    var encodedVal = "4rL4RCWHz3iNCdCaveD8KcHfV9YWGsqSHFPo7X2zBNwa";

    var decoder = Decoder.init(testing.allocator, .{});
    var decodedVal = try decoder.decode(encodedVal[0..]);
    defer testing.allocator.free(decodedVal);

    try testing.expect(std.mem.eql(u8, decodedVal, &original));
}

test "string as bytes encodes/decodes" {
    testing.log_level = std.log.Level.debug;

    var someMsg: [12]u8 = [12]u8{ 'H', 'e', 'l', 'l', 'o', ',', ' ', 'W', 'o', 'r', 'l', 'd' };
    var encoder = Encoder.init(testing.allocator, .{});

    var encodedVal = try encoder.encode(
        someMsg[0..],
    );
    defer testing.allocator.free(encodedVal);

    var decoder = Decoder.init(testing.allocator, .{});

    var decodedVal = try decoder.decode(encodedVal[0..]);
    defer testing.allocator.free(decodedVal);

    try testing.expect(std.mem.eql(u8, decodedVal, &someMsg));
}

test "should encode leading 0s slice properly" {
    testing.log_level = std.log.Level.debug;
    var arenaAllocator = std.heap.ArenaAllocator.init(testing.allocator);
    var allocator = arenaAllocator.allocator();

    var slice = [10]u8{ 0, 0, 13, 4, 5, 6, 3, 23, 64, 75 };

    var encoder = Encoder.init(allocator, .{});
    var encodedVal = try encoder.encode(
        &slice,
    );

    var decoder = Decoder.init(allocator, .{});

    var decodedVal = try decoder.decode(encodedVal);
    try testing.expect(std.mem.eql(u8, decodedVal, &slice));

    arenaAllocator.deinit();
}

test "should encode single byte slice" {
    testing.log_level = std.log.Level.debug;
    var arenaAllocator = std.heap.ArenaAllocator.init(testing.allocator);
    var allocator = arenaAllocator.allocator();

    var slice = [1]u8{255};

    var encoder = Encoder.init(allocator, .{});
    var encodedVal = try encoder.encode(
        &slice,
    );

    var decoder = Decoder.init(allocator, .{});
    var decodedVal = try decoder.decode(encodedVal);

    try testing.expect(std.mem.eql(u8, decodedVal, &slice));

    arenaAllocator.deinit();
}

test "should encode variable slice sizes" {
    testing.log_level = std.log.Level.debug;
    var arenaAllocator = std.heap.ArenaAllocator.init(testing.allocator);
    defer arenaAllocator.deinit();

    var allocator = arenaAllocator.allocator();

    var iters: usize = 1000;
    var i: usize = 0;
    var timer = try std.time.Timer.start();
    var encoder = Encoder.init(allocator, .{});
    var decoder = Decoder.init(allocator, .{});

    while (i < iters) : (i += 1) {
        var slice = try generateRandomByteSlice(allocator, i, 256);
        var encodedVal = try encoder.encode(
            slice,
        );

        var decodedVal = try decoder.decode(encodedVal);

        try testing.expect(std.mem.eql(u8, decodedVal, slice));
    }
    std.log.info("iters: {}, time: {}ms", .{ iters, timer.read() / 1000000 });
}

fn generateRandomByteSlice(allocator: std.mem.Allocator, seed: usize, maxLength: usize) ![]u8 {
    var rng = std.rand.DefaultPrng.init(@intCast(u64, std.time.timestamp() * @intCast(i64, seed)));
    const length = rng.random().uintAtMost(usize, maxLength);
    var slice = try allocator.alloc(u8, length);
    rng.random().bytes(slice);
    return slice;
}
