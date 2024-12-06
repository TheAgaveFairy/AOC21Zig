const std = @import("std");
const printerr = std.debug.print;

const Display = struct {
    mapping: [7]u8,
    const segments = [10][]const usize{
        &[_]usize{ 0, 1, 2, 4, 5, 6 },
        &[_]usize{ 2, 5 },
        &[_]usize{ 0, 2, 3, 4, 6 },
        &[_]usize{ 0, 2, 3, 5, 6 },
        &[_]usize{ 1, 2, 3, 5 },
        &[_]usize{ 0, 1, 3, 5, 6 },
        &[_]usize{ 0, 1, 3, 4, 5, 6 },
        &[_]usize{ 0, 2, 5 },
        &[_]usize{ 0, 1, 2, 3, 4, 5, 6 },
        &[_]usize{ 0, 1, 2, 3, 5, 6 },
    };

    // mapping uses the following:
    //  0000
    // 1    2
    // 1    2
    //  3333
    // 4    5
    // 4    5
    //  6666
    //  i.e. if mapping[3] = 'd' then the middle bar is 'd's (nuts)

    /// returns the number of solved segments
    pub fn checkStatus(self: *Display) usize {
        var count: usize = 0;
        for (self.mapping) |c| {
            if (std.ascii.isAlphabetic(c)) count += 1;
        }
        return count;
    }

    fn getIndex(self: *Display, char: u8) ?usize {
        var test_tracking: u8 = 0;
        for (self.mapping, 0..) |c, i| {
            test_tracking = c;
            if (char == c) return i;
        }
        printerr("how did we get here i{c} m{c}\n", .{ char, test_tracking });
        return null;
    }

    pub fn decodePatternToNum(self: *Display, pattern: []const u8) usize {
        var found = [_]bool{false} ** 7;
        for (pattern) |p| {
            const idx = self.getIndex(p) orelse unreachable;
            //printerr("TEST: {c} at {}\n", .{ p, idx });
            found[idx] = true;
        }
        outer: for (segments, 0..) |seg_list, i| { // gets one array of indices i.e. (0, 2, 5) for 7
            if (seg_list.len != pattern.len) continue;
            for (seg_list) |seg_idx| { // (0, 2, then 5)
                if (!found[seg_idx]) continue :outer;
            }
            return i;
        }
        return 9001; // error the power level is too high
    }

    pub fn print(self: Display) void {
        const template =
            \\  0000
            \\ 1    2
            \\ 1    2
            \\  3333
            \\ 4    5
            \\ 4    5
            \\  6666
            \\
        ;

        for (template) |c| {
            if (std.ascii.isDigit(c)) {
                //const idx = try std.fmt.parseInt(u4, c, 10); // u4 to feel ~special
                const idx = c - '0';
                printerr("{c}", .{self.mapping[idx]});
            } else {
                printerr("{c}", .{c});
            }
        }
        printerr("\n", .{});
    }
};

/// TODO: make 10 and 4 global consts or struct consts or something
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

    /// part one
    fn isUnique(pattern: []u8) bool {
        const answer = switch (pattern.len) {
            2 => true, // 1
            3 => true, // 7
            4 => true, // 4
            7 => true, // 8
            else => false,
        };
        return answer;
    }

    /// returns the missing letter from the haystack
    pub fn oddOneOut(smaller: []const u8, larger: []const u8) ?u8 {
        for (larger) |l| {
            var found = false;
            for (smaller) |s| {
                if (l == s) found = true;
            }
            if (!found) return l;
        }
        return null;
    }

    /// returns the actual character differences
    pub fn differenceBetweenSets(allocator: std.mem.Allocator, smaller: []const u8, larger: []const u8) !std.ArrayList(u8) {
        var different = std.ArrayList(u8).init(allocator);
        for (larger) |lg| {
            var found = false;
            for (smaller) |sm| {
                if (sm == lg) {
                    found = true;
                }
            }
            if (!found) {
                try different.append(lg);
            }
        }
        return different;
    }

    /// core functionality for part one
    pub fn countUniques(self: *Signal) usize {
        var count: usize = 0;
        for (self.outputs) |o| {
            if (isUnique(o)) count += 1;
        }
        return count;
    }

    /// TODO: move to Display struct
    pub fn buildDisplay(self: *Signal) !Display {
        var display: Display = undefined;

        var fives: [3][5]u8 = undefined; // @memcpy will mutate
        var sixes: [3][6]u8 = undefined; // @memcpy will mutate
        var five_idx: usize = 0;
        var six_idx: usize = 0;

        var one_chars = [_]u8{0} ** 2;
        var four_chars = [_]u8{0} ** 4;
        var seven_chars = [_]u8{0} ** 3;
        var eight_chars = [_]u8{0} ** 7; // all chars, useful later

        for (self.patterns) |pat| {
            switch (pat.len) { // the unique lens
                2 => @memcpy(&one_chars, pat), // display.setMapping(1, pat),
                3 => @memcpy(&seven_chars, pat),
                4 => @memcpy(&four_chars, pat),
                7 => @memcpy(&eight_chars, pat),
                5 => {
                    @memcpy(&fives[five_idx], pat);
                    five_idx += 1;
                },
                6 => {
                    @memcpy(&sixes[six_idx], pat);
                    six_idx += 1;
                },
                else => unreachable,
            }
        }

        display.mapping[0] = Signal.oddOneOut(&one_chars, &seven_chars) orelse unreachable;

        var one_three_candidates = [_]u8{0} ** 2; // segments one and three are in four but not one
        var idx: u2 = 0;
        for (four_chars) |four| {
            var found: bool = false;
            for (one_chars) |one| {
                if (one == four) found = true;
            }
            if (!found) {
                one_three_candidates[idx] = four;
                idx += 1;
            }
        }

        // 4 segs are a subset of 9s. this will now reveal segment 6!
        for (sixes) |six_chars| { // bad naming - six_chars contains the chars of signal patterns of *length* six
            var found_count: usize = 0;
            for (four_chars) |fc| {
                var found = false;
                for (six_chars) |sc| {
                    if (sc == fc) found = true;
                }
                if (found) found_count += 1;
            }
            if (found_count == 4) { // found all shared segments between 4 and 9, odd one out is segment 6
                for (six_chars) |sc| { // this (six_chars) is the number 9! (the chars of a pattern of len 6)
                    var found = false;
                    if (sc == display.mapping[0]) continue;
                    for (four_chars) |fc| {
                        if (fc == sc) found = true;
                    }
                    if (!found) display.mapping[6] = sc; // we can figure out segment 6 by process of elimination
                }
                display.mapping[4] = Signal.oddOneOut(&six_chars, &eight_chars) orelse unreachable;
            } else {
                //TODO: this is the only part that can error. maybe i could avoid that?
                // o/w found_count == 3, for digits 0 and 6
                const difference = try differenceBetweenSets(self.allocator, &six_chars, &one_chars); // 0 overlaps with 1 two times. 6 once.
                defer difference.deinit();
                if (difference.items.len == 1) { // we've found digit 6
                    display.mapping[2] = difference.items[0]; //Signal.oddOneOut(&six_chars, &one_chars) orelse unreachable;
                } else if (difference.items.len == 0) { // we've found digit 0
                    display.mapping[3] = Signal.oddOneOut(&six_chars, &eight_chars) orelse unreachable;
                } else {
                    printerr("UNREACHABLE: {}\n", .{difference.items.len});
                    for (difference.items) |d| printerr("{c} ", .{d});
                }
            }
        }

        // at this point we only needs segments 1 and 5

        // segment 5 is the other letter of one
        for (one_chars) |c| {
            if (c != display.mapping[2]) display.mapping[5] = c;
        }

        // one remaining
        for (eight_chars) |e| {
            var found = false;
            for (display.mapping) |d| {
                if (e == d) found = true;
            }
            if (!found) display.mapping[1] = e;
        }
        //display.print();
        return display;
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

fn partTwo(allocator: std.mem.Allocator) !usize {
    var signals = try readFile(allocator);
    defer signals.deinit();
    defer for (signals.items) |*sig| sig.deinit();
    var answer: usize = 0;
    for (signals.items) |*sig| {
        var display = try sig.buildDisplay();
        //display.print();
        var current: usize = 0;
        for (sig.outputs, 0..) |op, i| {
            const result = display.decodePatternToNum(op);
            //printerr("{s} : {}\n", .{ op, result });
            const factor = 1000 / std.math.pow(usize, 10, i);
            current += result * factor;
        }
        //printerr("{s} is {}\n", .{ sig.outputs, current });
        answer += current;
    }
    return answer;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const part_one_answer = try partOne(allocator);
    printerr("Part One Answer: {}\n", .{part_one_answer});

    const part_two_answer = try partTwo(allocator);
    printerr("Part Two Answer: {}\n", .{part_two_answer});
}
