const std = @import("std");
const printerr = std.debug.print;

const IslandTracker = struct {
    const COUNT = 3;
    var islands = [_]usize{0} ** COUNT;

    pub fn put(self: *IslandTracker, new_island_size: usize) void {
        if (new_island_size <= self.islands[0]) return;
        self.islands[0] = new_island_size;
        std.sort.insertion(usize, self.islands);
        return;
    }

    pub fn product(self: *IslandTracker) usize {
        var answer: usize = 1;
        for (self.islands) |i| answer *= i;
        return answer;
    }
};

inline fn idx(cols: usize, row: usize, col: usize) usize {
    return row * cols + col;
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

fn partTwo(allocator: std.mem.Allocator, filename: []const u8) !usize {
    const content: []u8 = try std.fs.cwd().readFileAlloc(allocator, filename, std.math.maxInt(usize));
    defer allocator.free(content);

    const cols = std.mem.indexOfScalar(u8, content, '\n').? + 1;
    // const rows = content.len / cols;

    var island_tracker: IslandTracker = undefined;

    for (content, 0..) |char, i| {
        if (char != 'a' and char < '9' and char >= '0') {
            const col = i % cols;
            const row = i / cols;
            printerr("island begins: ({},{})\n", .{ row, col });
            const island_size = try bfs(content, row, col);
            printerr("island size: {}\n", .{island_size});
            island_tracker.put(island_size);
        }
    }
    return island_tracker.product();
}

fn bfs(content: []u8, row: usize, col: usize) !usize {
    var answer: usize = 0;
    const cols = std.mem.indexOfScalar(u8, content, '\n').? + 1;
    const rows = content.len / cols;

    const char = content[row * cols + col];
    if (char < '9' and char != 'a' and char >= '0') {
        printerr("bfs({},{})\n", .{ row, col });
        answer += 1;
        content[row * cols + col] = 'a';

        if (row > 0) {
            answer += try bfs(content, row - 1, col);
        }
        if (row < rows - 1) {
            answer += try bfs(content, row + 1, col);
        }
        if (col > 0) {
            answer += try bfs(content, row, col - 1);
        }
        if (col < cols - 2) { // -2 because '\n's
            answer += try bfs(content, row, col + 1);
        }
    }
    return answer;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const filename = "../inputs/day9test.txt";
    const part_one_answer = try partOne(allocator, filename);
    printerr("Part One Answer: {}\n", .{part_one_answer});
    const part_two_answer = try partTwo(allocator, filename);
    printerr("Part Two Answer: {}\n", .{part_two_answer});
}
