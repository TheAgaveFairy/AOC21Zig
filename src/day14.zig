const std = @import("std");
const printerr = std.debug.print;

const PairCounter = struct {
    pairs: std.AutoHashMap([2]u8, usize),
    rules: std.AutoHashMap([2]u8, u8),
    counts: [26]usize,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) PairCounter {
        return .{
            .pairs = std.AutoHashMap([2]u8, usize).init(allocator),
            .rules = std.AutoHashMap([2]u8, u8).init(allocator),
            .counts = [_]usize{0} ** 26,
            .allocator = allocator,
        };
    }
    pub fn deinit(self: *PairCounter) void {
        self.pairs.deinit();
        self.rules.deinit();
    }

    pub fn incChar(self: *PairCounter, char: u8, value: usize) void {
        self.counts[char - 'A'] += value;
    }
    /// won't check for underflow
    pub fn decChar(self: *PairCounter, char: u8, value: usize) void {
        self.counts[char - 'A'] -= value;
    }

    pub fn incPair(self: *PairCounter, pair: [2]u8, value: usize) !void {
        if (self.pairs.getPtr(pair)) |val_ptr| {
            val_ptr.* = val_ptr.* + value;
        } else {
            try self.pairs.put(pair, value);
        }
    }

    pub fn decPair(self: *PairCounter, key: [2]u8, value: usize) void {
        const val_ptr = self.pairs.getPtr(key).?;
        const val = val_ptr.*;
        if (val > 0) val_ptr.* = val - value;
    }

    pub fn processInput(allocator: std.mem.Allocator, in_contents: []u8) !PairCounter {
        var answer = init(allocator);
        var contents = in_contents;

        const first_newl = std.mem.indexOfScalar(u8, contents, '\n').?;
        const first_line = contents[0..first_newl];
        try answer.buildPairs(first_line);
        contents = contents[first_newl + 1 ..];

        while (std.mem.indexOfScalar(u8, contents, '\n')) |newl| {
            if (newl == 0) {
                contents = contents[1..];
                continue;
            }
            const line = contents[0..newl];
            if (line.len < 2) break;
            var split_iter = std.mem.splitSequence(u8, line, " -> ");
            const pair_t = split_iter.next().?;
            const char_t = split_iter.next().?;

            const pair: [2]u8 = .{ pair_t[0], pair_t[1] };
            const char: u8 = char_t[0];
            try answer.addRule(pair, char);
            contents = contents[newl + 1 ..];
        }
        return answer;
    }

    pub fn addRule(self: *PairCounter, pair: [2]u8, char: u8) !void {
        try self.rules.put(pair, char);
    }

    pub fn buildPairs(self: *PairCounter, line: []u8) !void {
        var i: usize = 0;
        while (i < line.len - 1) : (i += 1) {
            self.incChar(line[i], 1);
            const pair = .{ line[i], line[i + 1] };
            try self.incPair(pair, 1);
        }
        self.incChar(line[line.len - 1], 1);
    }
    pub fn print(self: *PairCounter) void {
        var pair_iter = self.pairs.keyIterator();
        while (pair_iter.next()) |k| {
            if (self.pairs.get(k.*)) |val| {
                printerr("{str}: {} ", .{ k, val });
            }
        }
        printerr("\n", .{});
        for (self.counts, 0..) |count, pos| {
            const char: u8 = @intCast(pos + 'A');
            if (count > 0) printerr("{c}:{}, ", .{ char, count });
        }
        printerr("\n", .{});
    }
    pub fn elementStats(self: *PairCounter) usize {
        var max: usize = 0;
        var min: usize = std.math.maxInt(usize);

        for (self.counts) |count| {
            max = @max(max, count);
            if (count > 0) min = @min(min, count);
        }
        return max - min;
    }
};

pub fn partOne(allocator: std.mem.Allocator, contents: []u8) ![2]usize {
    var pair_counter = try PairCounter.processInput(allocator, contents);
    defer pair_counter.deinit();

    var answer: [2]usize = .{ 0, 0 };

    for (0..40) |i| {
        if (i == 10) answer[0] = pair_counter.elementStats();
        //pair_counter.print();
        var pairs_copy = try pair_counter.pairs.clone();
        defer pairs_copy.deinit();

        // how to iterate over AutoHashMap
        var pairs_iter = pairs_copy.iterator();
        while (pairs_iter.next()) |entry| {
            const key = entry.key_ptr.*;
            const val = entry.value_ptr.*;
            if (pair_counter.rules.getPtr(key)) |char_ptr| {
                //printerr("key: {str} -> {c}. {} times.\n", .{ key, char_ptr.*, val });
                try pair_counter.incPair(.{ key[0], char_ptr.* }, val);
                try pair_counter.incPair(.{ char_ptr.*, key[1] }, val);
                pair_counter.decPair(key, val);

                pair_counter.incChar(char_ptr.*, val);
            }
        }
    }
    //pair_counter.print();
    answer[1] = pair_counter.elementStats();
    return answer;

    //return 1337;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const filename = "../inputs/day14.txt";
    const content: []u8 = try std.fs.cwd().readFileAlloc(allocator, filename, std.math.maxInt(usize));
    defer allocator.free(content);

    const answer = try partOne(allocator, content);
    printerr("Part One Answer: {}\n", .{answer[0]});
    printerr("Part Two Answer: {}\n", .{answer[1]});
}
