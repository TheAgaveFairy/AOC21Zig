const std = @import("std");
const printerr = std.debug.print;

fn processLine(allocator: std.mem.Allocator, line: []const u8) !usize {
    var stack = std.ArrayList(u8).init(allocator);
    defer stack.deinit();

    for (line) |char| {
        printerr("{c} ", .{char});
        if (stack.items.len == 0) {
            try stack.append(char);
        } else {
            switch (char) {
                '(' => {
                    if (stack.getLast() == ')') {
                        _ = stack.pop();
                    } else {
                        try stack.append(char);
                    }
                },
                '[' => {
                    if (stack.getLast() == ']') {
                        _ = stack.pop();
                    } else {
                        try stack.append(char);
                    }
                },
                '{' => {
                    if (stack.getLast() == '}') {
                        _ = stack.pop();
                    } else {
                        try stack.append(char);
                    }
                },
                '<' => {
                    if (stack.getLast() == '>') {
                        _ = stack.pop();
                    } else {
                        try stack.append(char);
                    }
                },
                else => {
                    try stack.append(char);
                },
            }
        }
        printerr("Stack: ", .{});
        for (stack.items) |s| printerr("{c}", .{s});
        printerr("\n", .{});
    }
    printerr("\n\n\n", .{});
    return 69;
}

fn partOne(allocator: std.mem.Allocator, contents: []u8) !usize {
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        printerr("{s}\n", .{line});
        _ = try processLine(allocator, line);
    }
    return 9001;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const filename = "../inputs/day10test.txt";
    const content: []u8 = try std.fs.cwd().readFileAlloc(allocator, filename, std.math.maxInt(usize));
    defer allocator.free(content);

    const part_one_answer = try partOne(allocator, content);
    printerr("Part One Answer: {}\n", .{part_one_answer});
    //const part_two_answer = try partTwo(allocator, filename);
    //printerr("Part Two Answer: {}\n", .{part_two_answer});
}
