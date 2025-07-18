const std = @import("std");
const zbench = @import("zbench");
const CosLcsIterator = @import("cos.zig");

fn getRandomArray(random: *std.Random, comptime length: comptime_int, comptime alphabet_size: comptime_int) [length]u8 {
    var array: [length]u8 = undefined;
    for (&array) |*num| {
        num.* = random.int(u8) % alphabet_size;
    }
    return array;
}

fn CosLcsNextValueBenchmark(comptime length: comptime_int, comptime alphabet_size: comptime_int) type {
    return struct {
        source: [length]u8,
        target: [length]u8,

        fn init(random: *std.Random) @This() {
            return .{
                .source = getRandomArray(random, length, alphabet_size),
                .target = getRandomArray(random, length, alphabet_size),
            };
        }

        pub fn run(self: @This(), _: std.mem.Allocator) void {
            var iterator = CosLcsIterator.init(&self.source, &self.target);
            while (iterator.next()) |item| {
                std.mem.doNotOptimizeAway(item);
            }
        }
    };
}

pub fn main() !void {
    var prng = std.Random.DefaultPrng.init(std.testing.random_seed);
    var random = prng.random();

    const stdout = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var bench = zbench.Benchmark.init(allocator, .{});
    defer bench.deinit();

    const lengths = [_]comptime_int{ 10, 100, 250, 500, 1000, 1500, 2000 };
    const alphabet_sizes = [_]comptime_int{ 1, 2, 4, 16, 32, 64, 128, 255 };

    inline for (lengths) |length| {
        inline for (alphabet_sizes) |alphabet_size| {
            const name = std.fmt.comptimePrint(
                "CosLCs_L{d}_A{d}",
                .{ length, alphabet_size },
            );
            const benchmark = CosLcsNextValueBenchmark(length, alphabet_size).init(&random);
            try bench.addParam(name, &benchmark, .{});
        }
    }

    try stdout.writeAll("\n");
    try bench.run(stdout);
}
