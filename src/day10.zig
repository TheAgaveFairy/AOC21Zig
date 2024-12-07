const std = @import("std");
const printerr = std.debug.print;

inline fn getPair(char: u8) u8 {
    return switch (char) {
        ')' => '(',
        ']' => '[',
        '}' => '{',
        '>' => '<',
        '(' => ')',
        '[' => ']',
        '{' => '}',
        '<' => '>',
        else => unreachable,
    };
}

fn resolveStack(stack: []u8) !usize {
    var answer: usize = 0;
    var i: usize = stack.len;
    while (i > 0) {
        i -= 1;
        const char = stack[i];
        const value: usize = switch (char) {
            '(' => 1,
            '[' => 2,
            '{' => 3,
            '<' => 4,
            else => unreachable,
        };
        answer *= 5;
        answer += value;
    }
    return answer;
}

fn processLineTwo(allocator: std.mem.Allocator, line: []const u8) !usize {
    var stack = std.ArrayList(u8).init(allocator);
    defer stack.deinit();

    for (line) |char| {
        if (stack.items.len == 0) {
            try stack.append(char);
        } else {
            const last = stack.getLast();
            switch (char) {
                ')' => {
                    if (last == '(') {
                        _ = stack.pop();
                    } else {
                        return 0;
                    }
                },
                ']' => {
                    if (last == '[') {
                        _ = stack.pop();
                    } else {
                        return 0;
                    }
                },
                '}' => {
                    if (last == '{') {
                        _ = stack.pop();
                    } else {
                        return 0;
                    }
                },
                '>' => {
                    if (last == '<') {
                        _ = stack.pop();
                    } else {
                        return 0;
                    }
                },
                else => {
                    try stack.append(char);
                },
            }
        }
    }
    //printerr("Stack: ", .{});
    //for (stack.items) |s| printerr("{c}", .{s});
    //printerr("\n", .{});
    const line_value = try resolveStack(stack.items);
    //printerr("Stack Resolved Value: {}\n", .{line_value});
    return line_value;
}

fn processLine(allocator: std.mem.Allocator, line: []const u8) !usize {
    var stack = std.ArrayList(u8).init(allocator);
    defer stack.deinit();

    for (line) |char| {
        //printerr("{c} ", .{char});
        if (stack.items.len == 0) {
            try stack.append(char);
        } else {
            const last = stack.getLast();
            switch (char) {
                ')' => {
                    if (last == '(') {
                        _ = stack.pop();
                    } else {
                        //printerr("expected {c}, found {c}\n", .{ getPair(last), char });
                        return 3;
                    }
                },
                ']' => {
                    if (last == '[') {
                        _ = stack.pop();
                    } else {
                        //printerr("expected {c}, found {c}\n", .{ getPair(last), char });
                        return 57;
                    }
                },
                '}' => {
                    if (last == '{') {
                        _ = stack.pop();
                    } else {
                        //printerr("expected {c}, found {c}\n", .{ getPair(last), char });
                        return 1197;
                    }
                },
                '>' => {
                    if (last == '<') {
                        _ = stack.pop();
                    } else {
                        //printerr("expected {c}, found {c}\n", .{ getPair(last), char });
                        return 25137;
                    }
                },
                else => {
                    try stack.append(char);
                },
            }
        }
    }
    //printerr("\n\n\n", .{});
    //printerr("Stack: ", .{});
    //for (stack.items) |s| printerr("{c}", .{s});
    //printerr("\n", .{});

    return 0;
}

fn partOne(allocator: std.mem.Allocator, contents: []u8) !usize {
    var lines = std.mem.splitScalar(u8, contents, '\n');
    var answer: usize = 0;
    while (lines.next()) |line| {
        //printerr("{s}\n", .{line});
        answer += try processLine(allocator, line);
    }
    return answer;
}

fn partTwo(allocator: std.mem.Allocator, contents: []u8) !usize {
    var lines = std.mem.splitScalar(u8, contents, '\n');
    var values = std.ArrayList(usize).init(allocator);
    defer values.deinit();

    while (lines.next()) |line| {
        //printerr("{s}\n", .{line});
        if (line.len > 0) {
            const resolved: usize = try processLineTwo(allocator, line);
            if (resolved > 0) try values.append(resolved);
        }
    }
    std.sort.insertion(usize, values.items, {}, std.sort.asc(usize));
    //for (values.items) |v| printerr("{} ", .{v});
    const mid = values.items.len / 2;
    return values.items[mid];
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const filename = "../inputs/day10.txt";
    const content: []u8 = try std.fs.cwd().readFileAlloc(allocator, filename, std.math.maxInt(usize));
    defer allocator.free(content);

    const part_one_answer = try partOne(allocator, content);
    printerr("Part One Answer: {}\n", .{part_one_answer});
    const part_two_answer = try partTwo(allocator, content);
    printerr("Part Two Answer: {}\n", .{part_two_answer});
}
