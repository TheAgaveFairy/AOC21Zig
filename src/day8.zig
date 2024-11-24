const std = @import("std");
const printerr = std.debug.print;

const Display = struct {
    mapping: [7]u8,

    //  0000
    // 1    2
    // 1    2
    //  3333
    // 4    5
    // 4    5
    //  6666

    pub fn setMapping(self: *Display, num_to_set: usize, chars: []u8) void {
        const segments = [10][_]usize {
            {0, 1, 2, 4, 5, 6},
            {2, 5},
            {0, 2, 3, 4, 6},
            {0, 2, 3, 5, 6},
            {1, 2, 3, 5},
            {0, 1, 3, 5, 6},
            {0, 1, 3, 4, 5, 6},
            {0, 2, 5},
            {0, 1, 2, 3, 4, 5, 6},
            {0, 1, 2, 3, 5, 6},
        };
        std.debug.assert(chars.len == segments[num_to_set].len);
        for (chars, segments[num_to_set]) |c, i| self.mapping[i] = c;
    }
};

const Signal = struct {
    patterns: [10][]u8,
    outputs: [4][]u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Signal {
        return .{
            .patterns = undefined,
            .outputs = undefined,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Signal) void {
        for (0..10) |i| self.allocator.free(self.patterns[i]);
        for (0..4) |i| self.allocator.free(self.outputs[i]);
    }

    pub fn fromLine(allocator: std.mem.Allocator, line: []u8) !Signal {
        var signal = Signal.init(allocator);
        var line_iter = std.mem.splitScalar(u8, line, '|');

        const left_half = line_iter.next() orelse unreachable;
        const right_half = line_iter.next() orelse unreachable;
        const trimmed_left = std.mem.trim(u8, left_half, " ");
        const trimmed_right = std.mem.trim(u8, right_half, " ");

        var patterns_iter = std.mem.splitScalar(u8, trimmed_left, ' ');
        var outputs_iter = std.mem.splitScalar(u8, trimmed_right, ' ');

        // Patterns
        var i: usize = 0;
        while (patterns_iter.next()) |p| : (i += 1) {
            signal.patterns[i] = try allocator.dupe(u8, p);
        }
        std.debug.assert(i == 10);
        // Outputs
        i = 0;
        while (outputs_iter.next()) |o| : (i += 1) {
            signal.outputs[i] = try allocator.dupe(u8, o);
        }
        std.debug.assert(i == 4);
        return signal;
    }

    pub fn print(self: Signal) void {
        printerr("Patterns:\n", .{});
        for (self.patterns) |p| printerr("{s} ", .{p});
        printerr("\nOutputs:\n", .{});
        for (self.outputs) |o| printerr("{s} ", .{o});
        printerr("\n", .{});
    }

    fn isUnique(pattern: []u8) bool {
        const answer = switch (pattern.len) {
            2 => true, // 1
            3 => true, // 7
            4 => true, // 4
            7 => true, // 8
            else => false,
        };
        //printerr("{}:{} {s}\n", .{ pattern.len, answer, pattern });
        return answer;
    }

    pub fn countUniques(self: *Signal) usize {
        var count: usize = 0;
        //for (self.patterns) |p| {
        //    if (isUnique(p)) count += 1;
        //}
        for (self.outputs) |o| {
            if (isUnique(o)) count += 1;
        }
        return count;
    }
};

fn readFile(allocator: std.mem.Allocator) !std.ArrayList(Signal) {
    const infilename = "../inputs/day8.txt";
    var infile = try std.fs.cwd().openFile(infilename, .{});
    defer infile.close();

    var buf_reader = std.io.bufferedReader(infile.reader());
    const instream = buf_reader.reader();

    var signals = std.ArrayList(Signal).init(allocator);

    var buf: [4096]u8 = undefined;
    while (try instream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const sig: Signal = try Signal.fromLine(allocator, line);
        try signals.append(sig);
    }

    return signals;
}

fn partOne(allocator: std.mem.Allocator) !usize {
    var signals = try readFile(allocator);
    defer signals.deinit();
    defer for (signals.items) |*sig| sig.deinit();

    var uniques: usize = 0;
    for (signals.items) |*sig| {
        uniques += sig.countUniques();
    }

    return uniques;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const part_one_answer = try partOne(allocator);
    printerr("Part One Answer: {}\n", .{part_one_answer});
}
