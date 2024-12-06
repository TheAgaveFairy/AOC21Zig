const std = @import("std");
const printerr = std.debug.print;

inline fn idx(width: usize, row: usize, col: usize) usize {
    return row * width + col;
}

fn partOne(allocator: std.mem.Allocator, filename: []const u8) !usize {
    const content: []u8 = try std.fs.cwd().readFileAlloc(allocator, filename, std.math.maxInt(usize));
    defer allocator.free(content);
    const cols = std.mem.indexOf(u8, content, "\n").? + 1;
    const rows = content.len / cols;
    // printerr("cols: {} rows: {}\n", .{ cols - 1, rows });

    var total: usize = 0;
    outer: for (content, 0..) |char, i| {
        const col = i % cols;
        const row = i / cols;

        if (row > 0) {
            if (!(char < content[idx(cols, row - 1, col)])) continue :outer;
        }
        if (row < rows - 1) {
            if (!(char < content[idx(cols, row + 1, col)])) continue :outer;
        }
        if (col > 0) {
            if (!(char < content[idx(cols, row, col - 1)])) continue :outer;
        }
        if (col < cols - 2) { // -2 because '\n's
            if (!(char < content[idx(cols, row, col + 1)])) continue :outer;
        }
        const value = try std.fmt.parseInt(usize, &[_]u8{char}, 10);
        total += value + 1;
    }
    return total;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const filename = "../inputs/day9.txt";
    const part_one_answer = try partOne(allocator, filename);
    printerr("Part One Answer: {}\n", .{part_one_answer});
}
