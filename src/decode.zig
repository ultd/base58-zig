const std = @import("std");
const Alphabet = @import("./alphabet.zig").Alphabet;

pub const DecoderError = error{
    NonAsciiCharacter,
    InvalidCharacter,
    BufferTooSmall,
    OutOfMemory,
};

pub const Decoder = struct {
    alpha: Alphabet,

    const Self = @This();

    const Options = struct {
        alphabet: Alphabet = Alphabet.DEFAULT,
    };

    /// Initialize Decoder with options
    pub fn init(options: Options) Self {
        return Self{
            .alpha = options.alphabet,
        };
    }

    /// Pass a `allocator` & `encoded` bytes buffer. `decodeAlloc` will allocate a buffer
    /// to write into. It may also realloc as needed. Returned value is proper size.
    pub fn decodeAlloc(self: *const Self, allocator: std.mem.Allocator, encoded: []const u8) ![]u8 {
        var dest = try allocator.alloc(u8, encoded.len);
        const size = try decodeInteral(self.alpha, encoded, dest);
        if (dest.len != size) {
            dest = try allocator.realloc(dest, size);
        }
        return dest;
    }

    /// Pass a `encoded` and a `dest` to write decoded value into. `decode` returns a
    /// `usize` indicating how many bytes were written. Sizing/resizing, `dest` buffer is up to the caller.
    pub fn decode(self: *const Self, encoded: []const u8, dest: []u8) !usize {
        const size = try decodeInteral(self.alpha, encoded, dest);
        return size;
    }
};

fn decodeInteral(alpha: Alphabet, encoded: []const u8, dest: []u8) !usize {
    var index: usize = 0;
    const zero = alpha.encode[0];

    for (encoded) |c| {
        if (c > 127) {
            return DecoderError.NonAsciiCharacter;
        }

        var val: usize = alpha.decode[c];
        if (val == 0xFF) {
            return DecoderError.InvalidCharacter;
        }

        var x: usize = 0;
        while (x < index) : (x += 1) {
            const byte = &dest[x];
            val += @as(usize, @intCast(byte.*)) * 58;
            byte.* = @as(u8, @intCast(val & 0xFF));
            val >>= 8;
        }

        while (val > 0) {
            if (index >= dest.len) {
                return DecoderError.BufferTooSmall;
            }

            const byte = &dest[index];
            byte.* = @as(u8, @intCast(val)) & 0xFF;
            index += 1;
            val >>= 8;
        }
    }

    for (encoded) |*c| {
        if (c.* == zero) {
            const byte = &dest[index];
            byte.* = 0;
            index += 1;
        } else {
            break;
        }
    }

    std.mem.reverse(u8, dest[0..index]);

    return index;
}
