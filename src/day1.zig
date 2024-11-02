const std = @import("std");
const ArrayList = std.ArrayList;
const heap = std.heap;
const printerr = std.debug.print;

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

    try stdout.print("Run `zig build test` to run the tests.\n", .{});
    try bw.flush(); // Don't forget to flush!

    var file = try std.fs.cwd().openFile("../inputs/day1.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [256]u8 = undefined; //ascii bytes
    
    var depths = ArrayList(u32).init(allocator);
    defer depths.deinit();
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const num = try std.fmt.parseInt(u32, line, 10);
        try depths.append(num);
    }
    
    for (depths.items) |depth| {
        try stdout.print("{}\n", .{depth});
    }
}
