const std = @import("std");
pub const Self = @This();

pub const PairIndexes = struct {
    source_index: usize,
    target_index: usize,
};

const NO_INDEX = std.math.maxInt(usize);

source: []const u8,
target: []const u8,
last_pair_indexes: PairIndexes = .{ .source_index = 0, .target_index = 0 },
occurrence_buffer: [256]usize = [_]usize{NO_INDEX} ** 256,

pub fn init(source: []const u8, target: []const u8) Self {
    return Self{
        .source = source,
        .target = target,
    };
}

pub fn reset(self: *Self) void {
    self.last_pair_indexes = .{ .source_index = 0, .target_index = 0 };
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

pub fn peekPairIndexes(self: *Self) ?PairIndexes {
    const s_slice = self.source[self.last_pair_indexes.source_index..];
    const t_slice = self.target[self.last_pair_indexes.target_index..];
    const pair_indexes = nextPairOffsets(s_slice, t_slice, &self.occurrence_buffer);

    if (pair_indexes) |p| {
        return .{
            .source_index = self.last_pair_indexes.source_index + p.source_index,
            .target_index = self.last_pair_indexes.target_index + p.target_index,
        };
    }
    return null;
}

pub fn peekValue(self: *Self) ?u8 {
    if (self.peekPairIndexes()) |indexes| {
        return self.source[indexes.source_index];
    }
    return null;
}

pub fn nextPairIndexes(self: *Self) ?PairIndexes {
    if (self.peekPairIndexes()) |indexes| {
        self.last_pair_indexes.source_index = indexes.source_index + 1;
        self.last_pair_indexes.target_index = indexes.target_index + 1;
        return indexes;
    }
    return null;
}

pub fn nextValue(self: *Self) ?u8 {
    if (self.nextPairIndexes()) |indexes| {
        return self.source[indexes.source_index];
    }
    return null;
}

pub fn isEmpty(self: *Self) bool {
    return self.peekValue() == null;
}

test "nextPairOffsets" {
    var buffer: [256]usize = undefined;
    try std.testing.expectEqual(nextPairOffsets(&[_]u8{}, &[_]u8{}, &buffer), null);
    try std.testing.expectEqual(nextPairOffsets(&[_]u8{0}, &[_]u8{1}, &buffer), null);
    try std.testing.expectEqual(nextPairOffsets(&[_]u8{1}, &[_]u8{ 0, 1 }, &buffer) orelse unreachable, PairIndexes{ .source_index = 0, .target_index = 1 });
    try std.testing.expectEqual(nextPairOffsets(&[_]u8{ 2, 1, 0 }, &[_]u8{ 0, 1, 2 }, &buffer) orelse unreachable, PairIndexes{ .source_index = 0, .target_index = 2 });
    try std.testing.expectEqual(nextPairOffsets(&[_]u8{ 'a', 'b', 'c' }, &[_]u8{ 'c', 'b', 'a' }, &buffer) orelse unreachable, PairIndexes{ .source_index = 0, .target_index = 2 });
}

test "nextPairIndexes" {
    var iterator = Self.init(&[_]u8{ 2, 1, 0, 3 }, &[_]u8{ 0, 1, 2, 3 });
    try std.testing.expectEqual(iterator.nextPairIndexes() orelse unreachable, PairIndexes{ .source_index = 0, .target_index = 2 });
    try std.testing.expectEqual(iterator.nextPairIndexes() orelse unreachable, PairIndexes{ .source_index = 3, .target_index = 3 });
    try std.testing.expectEqual(iterator.nextPairIndexes(), null);
}

test "nextValue" {
    var iterator = Self.init(&[_]u8{ 2, 1, 0, 3 }, &[_]u8{ 0, 1, 2, 3 });
    try std.testing.expectEqual(iterator.nextValue() orelse unreachable, 2);
    try std.testing.expectEqual(iterator.nextValue() orelse unreachable, 3);
    try std.testing.expectEqual(iterator.nextValue(), null);
}

test "empty source" {
    var it = Self.init(&[_]u8{}, &[_]u8{ 1, 2, 3 });
    try std.testing.expect(it.isEmpty());
    try std.testing.expectEqual(it.nextValue(), null);
}

test "empty target" {
    var it = Self.init(&[_]u8{ 1, 2, 3 }, &[_]u8{});
    try std.testing.expect(it.isEmpty());
    try std.testing.expectEqual(it.nextValue(), null);
}

test "no common elements" {
    var it = Self.init(&[_]u8{ 1, 2, 3 }, &[_]u8{ 4, 5, 6 });
    try std.testing.expect(it.isEmpty());
    try std.testing.expectEqual(it.nextValue(), null);
}

test "repeated elements" {
    var it = Self.init("abacaba", "babacaba");
    try std.testing.expectEqualSlices(u8, &[_]u8{'a', 'b', 'a', 'c', 'a', 'b', 'a'}, &[_]u8{it.nextValue().?, it.nextValue().?, it.nextValue().?, it.nextValue().?, it.nextValue().?, it.nextValue().?, it.nextValue().?});
    try std.testing.expectEqual(it.nextValue(), null);
}

test "peek and next" {
    var it = Self.init("hello", "world");
    try std.testing.expectEqual(it.peekValue() orelse unreachable, 'l');
    try std.testing.expectEqual(it.peekValue() orelse unreachable, 'l');
    try std.testing.expectEqual(it.nextValue() orelse unreachable, 'l');
    try std.testing.expectEqual(it.peekValue() orelse unreachable, 'o');
    try std.testing.expectEqual(it.nextValue() orelse unreachable, 'o');
    try std.testing.expect(it.isEmpty());
}

test "reset" {
    var it = Self.init("abc", "cba");
    try std.testing.expectEqual(it.nextValue() orelse unreachable, 'a');
    it.reset();
    try std.testing.expectEqual(it.nextValue() orelse unreachable, 'a');
    try std.testing.expectEqual(it.nextValue() orelse unreachable, 'b');
    try std.testing.expectEqual(it.nextValue() orelse unreachable, 'c');
    try std.testing.expectEqual(it.nextValue(), null);
}

test "larger example" {
    const source = "the quick brown fox jumps over the lazy dog";
    const target = "a lazy dog is a friend of a quick brown fox";
    var it = Self.init(source, target);
    var result_buffer: [100]u8 = undefined;
    var result_slice = std.ArrayList(u8).init(result_buffer[0..]);
    defer result_slice.deinit();
    while (it.nextValue()) |v| {
        try result_slice.append(v);
    }
    try std.testing.expectEqualSlices(u8, "thequickbrownfoxlazydog", result_slice.items);
}