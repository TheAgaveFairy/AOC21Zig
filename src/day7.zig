const std = @import("std");
const printerr = std.debug.print;

const Fish = struct {
    time: u8,
    new: bool,
};

fn readFile(allocator: std.mem.Allocator) !std.ArrayList(u16) {
    const infilename = "../inputs/day7test.txt";
    var infile = try std.fs.cwd().openFile(infilename, .{});
    defer infile.close();

    var buf_reader = std.io.bufferedReader(infile.reader());
    const instream = buf_reader.reader();

    var fishes = std.ArrayList(u16).init(allocator); // copying code from day 6 about lanternfish!

    var buf: [1024]u8 = undefined;
    const line = try instream.readUntilDelimiterOrEof(&buf, '\n') orelse unreachable;
    const trimmed_line = std.mem.trim(u8, line, " ");

    var input_iter = std.mem.splitScalar(u8, trimmed_line, ',');
    while (input_iter.next()) |numstr| {
        const num = try std.fmt.parseInt(u16, numstr, 10);
        try fishes.append(num);
    }

    return fishes;
}

fn calcCost(positions: []usize, cost_point:usize) usize {
    var total: usize = 0;
    for (positions, 0..) |count, i| {
        const distance = @abs(@as(isize, i) - @as(isize, cost_point));
        total += distance * count;
    }
    return total;
}

fn partOne(allocator: std.mem.Allocator) !usize {
    var crabs = try readFile(allocator);
    defer crabs.deinit();
    
    var furthest: usize = 0;
    for (crabs.items) |crab| furthest = @max(furthest, crab);
    printerr("Furthest: {}\n", .{furthest});

    var positions = try allocator.alloc(usize, furthest+1);
    @memset(positions, 0);
    defer allocator.free(positions);

    for (crabs.items) |crab| positions[crab] += 1;
    printerr("{}\n", .{calcCost(positions,8)});
    return 1337;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const part_one_answer = try partOne(allocator);
    printerr("Part One Answer: {}\n", .{part_one_answer});

}
