const std = @import("std");
const ArrayList = std.ArrayList;
const heap = std.heap;
const printerr = std.debug.print;

fn partOne(depths: []const usize) usize {
    var answer: usize = 0;
    for (depths[1..], 0..) |curr, i| {
        const prev = depths[i];
        if (curr > prev) answer += 1;
    }
    return answer;
}

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var file = try std.fs.cwd().openFile("../inputs/day1.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [256]u8 = undefined; //ascii bytes
    
    var depths = ArrayList(usize).init(allocator);
    defer depths.deinit();
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const num = try std.fmt.parseInt(usize, line, 10);
        try depths.append(num);
    }
    
    var answer: usize = 0; // -1 accounts for depths[0] case returning "True"
    //try stdout.print("0: {} BASE CASE", .{depths.items[0]});
    for (depths.items[1..], 0..) |curr, i| {
        const prev = depths.items[i];
        //const gt = prev < curr;
        if (prev < curr) answer += 1;
        //try stdout.print("{}: {} {}\n", .{i+1, curr, gt});
    }
    try bw.flush();

    std.debug.print("Loop Done.\n", .{});
    try stdout.print("Part One: Number Increasing: {}.\n", .{answer});
    try bw.flush();

    const p1 = partOne(depths.items);
    std.debug.print("From fn(): {}.\n", .{p1});
}
