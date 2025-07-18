const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const CosLcsIterator = @This();

/// A pair representing a common item and its location in the source and target slices.
pub const Pair = struct {
    /// The common item found.
    item: u8,
    /// The index of the item in the original source slice.
    source_index: usize,
    /// The index of the item in the original target slice.
    target_index: usize,
};

/// Represents the iterator's current position within the source and target slices.
pub const Cursor = struct {
    source_index: usize,
    target_index: usize,
};

source: []const u8,
target: []const u8,
cursor: Cursor,
occurrences: [256]usize,

const NO_INDEX = std.math.maxInt(usize);

/// Initializes a new `CosLcsIterator` with the given source and target slices.
pub fn init(source: []const u8, target: []const u8) CosLcsIterator {
    return CosLcsIterator{
        .source = source,
        .target = target,
        .cursor = .{ .source_index = 0, .target_index = 0 },
        .occurrences = [_]usize{NO_INDEX} ** 256,
    };
}

/// Resets the iterator's cursor to the beginning of the source and target slices,
/// allowing the iteration to be restarted.
pub fn reset(self: *CosLcsIterator) void {
    self.cursor = .{ .source_index = 0, .target_index = 0 };
}

/// Advances the iterator and returns the next common item as a `u8`.
/// Returns `null` if no more common items are found.
pub fn next(self: *CosLcsIterator) ?u8 {
    const pair = self.nextPair() orelse return null;
    return pair.item;
}

/// Advances the iterator and returns the next common `Pair`.
///
/// This method contains the core logic of the iterator. It finds the next pair
/// of matching items by searching for the element that minimizes the sum of its
/// index in the source slice and its first occurrence in the target slice.
///
/// Returns `null` if no more common pairs are found.
pub fn nextPair(self: *CosLcsIterator) ?Pair {
    const s_slice = self.source[self.cursor.source_index..];
    const t_slice = self.target[self.cursor.target_index..];

    @memset(&self.occurrences, NO_INDEX);
    for (t_slice, 0..) |item, index| {
        if (self.occurrences[item] == NO_INDEX) {
            self.occurrences[item] = index;
        }
    }

    var min_sum: usize = NO_INDEX;
    var result_pair: ?Pair = null;

    for (s_slice, 0..) |item, s_idx| {
        const t_idx = self.occurrences[item];
        if (t_idx != NO_INDEX) {
            const sum = s_idx + t_idx;
            if (sum < min_sum) {
                min_sum = sum;
                result_pair = .{
                    .item = item,
                    .source_index = self.cursor.source_index + s_idx,
                    .target_index = self.cursor.target_index + t_idx,
                };
                if (sum == 0) break;
            }
            if (s_idx >= min_sum) break;
        }
    }

    if (result_pair) |p| {
        self.cursor.source_index = p.source_index + 1;
        self.cursor.target_index = p.target_index + 1;
    }

    return result_pair;
}

test next {
    var it = CosLcsIterator.init(&[_]u8{ 2, 1, 0, 3 }, &[_]u8{ 0, 1, 2, 3 });
    try testing.expectEqual(@as(?u8, 2), it.next());
    try testing.expectEqual(@as(?u8, 3), it.next());
    try testing.expectEqual(@as(?u8, null), it.next());
}

test nextPair {
    var it = CosLcsIterator.init(&[_]u8{ 2, 1, 0 }, &[_]u8{ 0, 1, 2 });

    var pair = it.nextPair();
    try testing.expect(pair != null);
    try testing.expectEqual(@as(u8, 2), pair.?.item);
    try testing.expectEqual(@as(usize, 0), pair.?.source_index);
    try testing.expectEqual(@as(usize, 2), pair.?.target_index);

    pair = it.nextPair();
    try testing.expectEqual(null, pair);
}

test reset {
    var it = CosLcsIterator.init("abc", "cba");

    try testing.expectEqual(@as(?u8, 'a'), it.next());
    try testing.expectEqual(null, it.next());

    it.reset();
    try testing.expectEqual(@as(?u8, 'a'), it.next());
    try testing.expectEqual(null, it.next());
}
