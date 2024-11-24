const std = @import("std");
const printerr = std.debug.print;

const Fish = struct {
    time: u8,
    new: bool,
};

fn readFile(allocator: std.mem.Allocator) !std.ArrayList(u16) {
    const infilename = "../inputs/day7.txt";
    var infile = try std.fs.cwd().openFile(infilename, .{});
    defer infile.close();

    var buf_reader = std.io.bufferedReader(infile.reader());
    const instream = buf_reader.reader();

    var fishes = std.ArrayList(u16).init(allocator); // copying code from day 6 about lanternfish!

    var buf: [4096]u8 = undefined;
    const line = try instream.readUntilDelimiterOrEof(&buf, '\n') orelse unreachable;
    const trimmed_line = std.mem.trim(u8, line, " ");

    var input_iter = std.mem.splitScalar(u8, trimmed_line, ',');
    while (input_iter.next()) |numstr| {
        const num = try std.fmt.parseInt(u16, numstr, 10);
        try fishes.append(num);
    }

    return fishes;
}

inline fn getDistance(i: usize, p: usize) usize {
    return if (i > p) i - p else p - i;
}

fn calcCostTwo(positions: []usize, p: usize) usize {
    var total: usize = 0;
    for (positions, 0..) |count, i| {
        const distance = getDistance(i,p);
        const sum_distances = distance * (distance + 1) / 2;
        total += sum_distances * count;
    }
    return total;
}

fn calcCost(positions: []usize, p: usize) usize {
    var total: usize = 0;
    for (positions, 0..) |count, i| {
        const distance = getDistance(i,p);
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

    var left: usize = 0;
    var right = furthest;
    var cost_nxt: usize = 0;
    var cost_mid: usize = 0;
    while (left < right) {
        const mid = left + (right-left) / 2;
        cost_mid = calcCostTwo(positions, mid); // change these to just calcCost for pt 1, im lazy
        cost_nxt = calcCostTwo(positions, mid + 1);
    
        if (cost_mid > cost_nxt) {
            left = mid + 1;
        } else {
            right = mid;
        }
        printerr("l{} r{} costmid{}\n", .{left,right,cost_nxt});
    }
    return cost_mid;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const part_one_answer = try partOne(allocator);
    printerr("Part One Answer: {}\n", .{part_one_answer});

}
