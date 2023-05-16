const std = @import("std");
const Alphabet = @import("./alphabet.zig").Alphabet;

pub const Error = error{
    NonAsciiCharacter,
    InvalidCharacter,
    BufferTooSmall,
};

pub const Decoder = struct {
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

    pub fn decode(self: Self, input: []const u8) ![]u8 {
        return decodeInteral(self.allocator, self.alpha, input);
    }
};

fn decodeInteral(allocator: std.mem.Allocator, alpha: Alphabet, input: []const u8) ![]u8 {
    var output = try allocator.alloc(u8, input.len);

    var index: usize = 0;
    var zero = alpha.encode[0];

    for (input) |c| {
        if (c > 127) {
            return Error.NonAsciiCharacter;
        }

        var val: usize = alpha.decode[c];
        if (val == 0xFF) {
            return Error.InvalidCharacter;
        }

        var x: usize = 0;
        while (x < index) : (x += 1) {
            var byte = &output[x];
            val += @intCast(usize, byte.*) * 58;
            byte.* = @intCast(u8, val & 0xFF);
            val >>= 8;
        }

        while (val > 0) {
            if (index >= output.len) {
                return Error.BufferTooSmall;
            }

            var byte = &output[index];
            byte.* = @intCast(u8, val) & 0xFF;
            index += 1;
            val >>= 8;
        }
    }

    for (input) |*c| {
        if (c.* == zero) {
            var byte = &output[index];
            byte.* = 0;
            index += 1;
        } else {
            break;
        }
    }

    if (output.len != index) {
        output = try allocator.realloc(output, index);
    }

    std.mem.reverse(u8, output);

    return output;
}
