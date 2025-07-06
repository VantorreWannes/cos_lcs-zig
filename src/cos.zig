const std = @import("std");
pub export const CosLcsIterator = @This();

pub export const PairIndexes = struct {
    source_index: usize,
    target_index: usize,
};

const NO_INDEX = std.math.maxInt(usize);

source: []const u8,
target: []const u8,
last_pair_indexes: PairIndexes = .{ .source_index = 0, .target_index = 0 },
occurrence_buffer: [256]usize = [_]usize{NO_INDEX} ** 256,

pub export fn init(source: []const u8, target: []const u8) CosLcsIterator {
    return CosLcsIterator{
        .source = source,
        .target = target,
    };
}

pub export fn reset(self: *CosLcsIterator) void {
    self.last_pair_indexes = .{ .source_index = 0, .target_index = 0 };
    self.occurence_buffer = []usize{NO_INDEX} ** 256;
}

fn nextPairOffsets(source: []const u8, target: []const u8, occurrence_buffer: *[256]usize) ?PairIndexes {
    @memset(occurrence_buffer, NO_INDEX);
    for (target, 0..) |value, index| {
        if (occurrence_buffer[value] == NO_INDEX) {
            occurrence_buffer[value] = index;
        }
    }

    var min_sum: usize = NO_INDEX;
    var result: ?PairIndexes = null;

    for (source, 0..) |source_value, source_index| {
        const target_index = occurrence_buffer[source_value];
        if (target_index != NO_INDEX) {
            const sum = source_index + target_index;
            if (sum < min_sum) {
                min_sum = sum;
                result = PairIndexes{ .source_index = source_index, .target_index = target_index };
                if (sum == 0) {
                    break;
                }
            }

            if (source_index >= min_sum) {
                break;
            }
        }
    }

    return result;
}

pub export fn nextPairIndexes(self: *CosLcsIterator) ?PairIndexes {
    const s_slice = self.source[self.last_pair_indexes.source_index..];
    const t_slice = self.target[self.last_pair_indexes.target_index..];
    const pair_indexes = nextPairOffsets(s_slice, t_slice, &self.occurrence_buffer);

    if (pair_indexes) |p| {
        self.last_pair_indexes.source_index += p.source_index + 1;
        self.last_pair_indexes.target_index += p.target_index + 1;
        return .{
            .source_index = self.last_pair_indexes.source_index - 1,
            .target_index = self.last_pair_indexes.target_index - 1,
        };
    }
    return null;
}

pub export fn nextValue(self: *CosLcsIterator) ?u8 {
    if (self.nextPairIndexes()) |indexes| {
        return self.source[indexes.source_index];
    }
    return null;
}

test nextPairOffsets {
    try std.testing.expectEqual(nextPairOffsets(&[_]u8{}, &[_]u8{}), null);
    try std.testing.expectEqual(nextPairOffsets(&[_]u8{0}, &[_]u8{1}), null);
    try std.testing.expectEqual(nextPairOffsets(&[_]u8{1}, &[_]u8{ 0, 1 }) orelse unreachable, PairIndexes{ .source_index = 0, .target_index = 1 });
    try std.testing.expectEqual(nextPairOffsets(&[_]u8{ 2, 1, 0 }, &[_]u8{ 0, 1, 2 }) orelse unreachable, PairIndexes{ .source_index = 0, .target_index = 2 });
}

test nextPairIndexes {
    var iterator = CosLcsIterator.init(&[_]u8{ 2, 1, 0, 3 }, &[_]u8{ 0, 1, 2, 3 });
    try std.testing.expectEqual(iterator.nextPairIndexes() orelse unreachable, PairIndexes{ .source_index = 0, .target_index = 2 });
    try std.testing.expectEqual(iterator.nextPairIndexes() orelse unreachable, PairIndexes{ .source_index = 3, .target_index = 3 });
    try std.testing.expectEqual(iterator.nextPairIndexes(), null);
}

test nextValue {
    var iterator = CosLcsIterator.init(&[_]u8{ 2, 1, 0, 3 }, &[_]u8{ 0, 1, 2, 3 });
    try std.testing.expectEqual(iterator.nextValue() orelse unreachable, 2);
    try std.testing.expectEqual(iterator.nextValue() orelse unreachable, 3);
    try std.testing.expectEqual(iterator.nextValue(), null);
}
