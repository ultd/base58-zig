const std = @import("std");
const testing = std.testing;
const Alphabet = @import("./alphabet.zig").Alphabet;

const Error = error{
    DestBuffTooSmall,
    BufResizeFailed,
};

pub const Encoder = struct {
    allocator: std.mem.Allocator,
    alpha: Alphabet,

    const Self = @This();

    const Options = struct {
        alphabet: Alphabet = Alphabet.DEFAULT,
    };

    pub fn init(allocator: std.mem.Allocator, options: Options) Self {
        return Self{
            .allocator = allocator,
            .alpha = options.alphabet,
        };
    }

    pub fn encode(self: Self, source: []u8) ![]u8 {
        return encodeInternal(self.allocator, self.alpha, source);
    }
};

fn encodeInternal(allocator: std.mem.Allocator, alpha: Alphabet, source: []u8) ![]u8 {
    var dest = try allocator.alloc(u8, source.len * 2);
    var index: usize = 0;

    for (source, 0..) |inputByte, i| {
        _ = i;
        var carry: usize = inputByte;

        var x: usize = 0;
        while (x < index) {
            carry += @as(usize, dest[x]) * 256;
            dest[x] = @intCast(u8, carry % 58);
            carry /= 58;
            x += 1;
        }

        while (carry > 0) {
            if (index == dest.len) {
                return Error.DestBuffTooSmall;
            }
            dest[index] = @intCast(u8, (carry % 58));
            index += 1;
            carry /= 58;
        }
    }

    for (source, 0..) |inputByte, i| {
        _ = i;
        if (inputByte == 0) {
            if (index == dest.len) {
                return Error.DestBuffTooSmall;
            }
            dest[index] = 0;
            index += 1;
        } else {
            break;
        }
    }

    var y: usize = 0;
    while (y < index) {
        dest[y] = alpha.encode[dest[y]];
        y += 1;
    }

    if (dest.len != index) {
        dest = try allocator.realloc(dest, index);
    }

    std.mem.reverse(u8, dest[0..index]);

    return dest;
}
