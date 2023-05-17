const std = @import("std");
const testing = std.testing;
const Alphabet = @import("./alphabet.zig").Alphabet;

const EncoderError = error{ DestBuffTooSmall, BufResizeFailed, OutOfMemory };

pub const Encoder = struct {
    alpha: Alphabet,

    const Self = @This();

    const Options = struct {
        alphabet: Alphabet = Alphabet.DEFAULT,
    };

    /// Initialize Encoder with options
    pub fn init(options: Options) Self {
        return Self{
            .alpha = options.alphabet,
        };
    }

    /// Pass an `allocator` & `source` bytes buffer. `encodeAlloc` will allocate a buffer
    /// to write into. It may also realloc as needed. Returned value is base58 encoded string.
    pub fn encodeAlloc(self: *const Self, allocator: std.mem.Allocator, source: []const u8) EncoderError![]u8 {
        var dest = try allocator.alloc(u8, source.len * 2);
        var size = try encodeInternal(self.alpha, source, dest);
        if (dest.len != size) {
            dest = try allocator.realloc(dest, size);
        }
        return dest;
    }

    /// Pass a `source` and a `dest` to write encoded value into. `encode` returns a
    /// `usize` indicating how many bytes were written. Sizing/resizing, `dest` buffer is up to the caller.
    pub fn encode(self: *const Self, source: []const u8, dest: []u8) EncoderError!usize {
        var size = try encodeInternal(self.alpha, source, dest);
        return size;
    }
};

fn encodeInternal(alpha: Alphabet, source: []const u8, dest: []u8) EncoderError!usize {
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
                return EncoderError.DestBuffTooSmall;
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
                return EncoderError.DestBuffTooSmall;
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

    std.mem.reverse(u8, dest[0..index]);

    return index;
}
