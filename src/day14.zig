const std = @import("std");
const printerr = std.debug.print;

const PairCounter = struct {
    pairs: std.AutoHashMap([2]u8, usize),
    rules: std.AutoHashMap([2]u8, u8),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) PairCounter {
        return .{
            .pairs = std.AutoHashMap([2]u8, usize).init(allocator),
            .rules = std.AutoHashMap([2]u8, u8).init(allocator),
            .allocator = allocator,
        };
    }
    pub fn deinit(self: *PairCounter) void {
        self.pairs.deinit();
        self.rules.deinit();
    }

    pub fn incPair(self: *PairCounter, pair: [2]u8) !void {
        if (self.pairs.getPtr(pair)) |val_ptr| {
            val_ptr.* = val_ptr.* + 1;
        } else {
            try self.pairs.put(pair, 0);
        }
    }

    pub fn decPair(self: *PairCounter, key: [2]u8) void {
        const val_ptr = self.pairs.getPtr(key).?;
        const val = val_ptr.*;
        if (val > 0) val_ptr.* = val - 1;
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
        while (i < line.len) : (i += 2) {
            const pair = .{ line[i], line[i + 1] };
            try self.incPair(pair);
        }
    }
    pub fn print(self: *PairCounter) void {
        var pair_iter = self.pairs.keyIterator();
        while (pair_iter.next()) |k| {
            printerr("{str}", .{k});
        }
        printerr("\n", .{});
    }
};

pub fn partOne(allocator: std.mem.Allocator, contents: []u8) !usize {
    var pair_counter = try PairCounter.processInput(allocator, contents);
    defer pair_counter.deinit();

    for (0..4) |_| {
        pair_counter.print();
        const num_pairs = pair_counter.pairs.count();
        var adds = try allocator.alloc([2]u8, 2 * num_pairs);
        defer allocator.free(adds);
        var subs = try allocator.alloc([2]u8, num_pairs);
        defer allocator.free(subs);

        // how to iterate over AutoHashMap
        var pairs_iter = pair_counter.pairs.iterator();
        var adds_idx: usize = 0;
        var subs_idx: usize = 0;
        while (pairs_iter.next()) |entry| {
            const key = entry.key_ptr.*;
            if (pair_counter.rules.getPtr(key)) |char_ptr| {
                adds[adds_idx] = .{ key[0], char_ptr.* };
                adds_idx += 1;
                adds[adds_idx] = .{ char_ptr.*, key[1] };
                adds_idx += 1;
                subs[subs_idx] = key;
                subs_idx += 1;
            }
        }

        for (0..adds_idx) |i| try pair_counter.incPair(adds[i]);
        for (0..subs_idx) |i| pair_counter.decPair(subs[i]);
    }
    pair_counter.print();

    return 1337;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const filename = "../inputs/day14test.txt";
    const content: []u8 = try std.fs.cwd().readFileAlloc(allocator, filename, std.math.maxInt(usize));
    defer allocator.free(content);

    const part_one_answer = try partOne(allocator, content);
    printerr("Part One Answer: {}\n", .{part_one_answer});
}
