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

    //  0000
    // 1    2
    // 1    2
    //  3333
    // 4    5
    // 4    5
    //  6666

    pub fn setMapping(self: *Display, num_to_set: usize, chars: []u8) void {
        std.debug.assert(chars.len == Display.segments[num_to_set].len);
        for (chars, Display.segments[num_to_set]) |c, i| self.mapping[i] = c;
    }

    fn inPattern(self: *Display, pattern: []const usize, chars: []u8) bool {
        for (pattern) |idx| { // example 1 gives 2 and 5, use with mapping to get their set chars
            const key_char = self.mapping[idx];
            const found = std.mem.containsAtLeast(u8, key_char, 1, chars);
            if (!found) return false;
        }
        return true;
    }

    pub fn dealWithFives(self: *Display, fives: [3][5]u8) void {
        // 2 3 5
        // 2 and 3 differ on (4) vs (5). 5 only shares (0,3,6)

        // 3 shares with 1 uniquely
        for (fives) |pat| {
            if (inPattern(self, Display.segments[1], pat)) {
                self.setMapping(3, pat);
            }
        }
    }
    pub fn dealWithSixes(self: *Display, sixes: [3][6]u8) void {
        // 0 6 9
        // 6 and 9 share (3) and differ on (2) vs (4).
        for (sixes) |pat| {
            //const testing = [_]usize{ 3, 4 };
            if (inPattern(self, Display.segments[1], pat) and false) { // this is boilerplate - NOT CORRECT NOR ROBUST AND IS ERROR-PRONE
                self.setMapping(6, pat);
            }
        }
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
        for (self.outputs) |o| {
            if (isUnique(o)) count += 1;
        }
        return count;
    }

    pub fn buildDisplay(self: *Signal) Display {
        var display: Display = undefined;

        var fives: [3][5]u8 = undefined; // @memcpy will mutate
        var sixes: [3][6]u8 = undefined; // @memcpy will mutate
        var five_idx: usize = 0;
        var six_idx: usize = 0;

        for (self.patterns) |pat| {
            switch (pat.len) { // the unique lens
                2 => display.setMapping(1, pat),
                3 => display.setMapping(7, pat),
                4 => display.setMapping(4, pat),
                7 => display.setMapping(8, pat),
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
        display.dealWithFives(fives);
        display.dealWithSixes(sixes);
        display.print();
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

    for (signals.items) |*sig| {
        const display = sig.buildDisplay();
        display.print();
    }
    return 420;
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
