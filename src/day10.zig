const std = @import("std");
const printerr = std.debug.print;

fn processLine(allocator: std.mem.Allocator, line: []const u8) !usize {
    var stack = std.ArrayList(u8).init(allocator);
    for (line) |char| {
        switch (char) {
            '[' => {
                if (stack.getLastOrNull()) |*last| {
                    if (last == ']') stack.pop();
                }
            },
            else => {
                try stack.append(char);
            },
        }
        printerr("{any}\n", .{stack});
    }
    return 69;
}

fn partOne(allocator: std.mem.Allocator, contents: []u8) !usize {
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        printerr("{s}\n", .{line});
        _ = processLine(allocator, line);
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
