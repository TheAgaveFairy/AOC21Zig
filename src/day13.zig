const std = @import("std");
const printerr = std.debug.print;

const Sheet = struct {
    data: []bool,
    width: usize,
    height: usize,
    x_fold: ?usize,
    y_fold: ?usize,

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, w: usize, h: usize) !Sheet {
        const data = try allocator.alloc(bool, w * h);
        @memset(data, false);
        return .{ .data = data, .width = w, .height = h, .x_fold = null, .y_fold = null, .allocator = allocator };
    }
    pub fn deinit(self: *Sheet) void {
        self.allocator.free(self.data);
    }

    pub fn set(self: *Sheet, x: usize, y: usize, val: bool) void {
        self.data[y * self.width + x] = val;
    }

    pub fn get(self: *Sheet, x: usize, y: usize) bool {
        return self.data[y * self.width + x];
    }

    pub fn countDots(self: *Sheet) usize {
        var answer: usize = 0;
        for (self.data, 0..) |d, i| {
            const x = i % self.width;
            const y = i / self.width;

            if (self.x_fold) |xf| {
                if (x >= xf) continue;
            }
            if (self.y_fold) |yf| {
                if (y >= yf) break;
            }

            if (d) answer += 1;
        }
        return answer;
    }

    pub fn preProcess(in_contents: []u8) ![2]usize {
        var w: usize = 0;
        var h: usize = 0;

        var contents = in_contents;
        while (std.mem.indexOfScalar(u8, contents, '\n')) |newl| {
            const line = contents[0..newl];
            if (line.len < 2) break;
            var split_iter = std.mem.splitScalar(u8, line, ',');
            const x_temp = split_iter.next().?;
            const y_temp = split_iter.next().?;

            const x = try std.fmt.parseInt(usize, x_temp, 10);
            const y = try std.fmt.parseInt(usize, y_temp, 10);

            if (x > w) w = x;
            if (y > h) h = y;

            contents = contents[newl + 1 ..];
        }
        return .{ w + 1, h + 1 }; // 0-indexed
    }

    pub fn process(self: *Sheet, in_contents: []u8) !void {
        var contents = in_contents;
        while (std.mem.indexOfScalar(u8, contents, '\n')) |newl| {
            const line = contents[0..newl];
            if (line.len < 2) break;
            var split_iter = std.mem.splitScalar(u8, line, ',');
            const x_temp = split_iter.next().?;
            const y_temp = split_iter.next().?;

            const x = try std.fmt.parseInt(usize, x_temp, 10);
            const y = try std.fmt.parseInt(usize, y_temp, 10);

            self.set(x, y, true);
            contents = contents[newl + 1 ..];
        }
    }
    pub fn print(self: *Sheet) void {
        for (self.data, 0..) |b, i| {
            if (self.y_fold) |yf| {
                if (i / self.width == yf) break;
            }
            if (i > 0 and i % self.width == 0) printerr("\n", .{});
            const p: u8 = if (b) '#' else '.';
            printerr("{c}", .{p});
        }
        printerr("\n", .{});
    }

    pub fn foldY(self: *Sheet, y: usize) void {
        self.y_fold = y;
        var idx = (y + 1) * self.width;
        var i: usize = 0;
        var j: usize = y;

        printerr("starting fold at position: {} -> ({},{})\n", .{ idx, i, j });
        while (idx < self.data.len) {
            const new_y = self.height - j - 1;
            const b = self.data[idx] or self.get(i, new_y);
            self.set(i, new_y, b);
            idx += 1;
            i = idx % self.width;
            j = idx / self.width;
        }
    }
};

pub fn partOne(allocator: std.mem.Allocator, contents: []u8) !usize {
    const size = try Sheet.preProcess(contents);
    const w = size[0];
    const h = size[1];
    var sheet = try Sheet.init(allocator, w, h);
    defer sheet.deinit();
    printerr("sheet size: {} {}\n", .{ sheet.width, sheet.height });

    try sheet.process(contents);
    sheet.print();

    sheet.foldY(7);
    sheet.print();

    return sheet.countDots();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const filename = "../inputs/day13.txt";
    const content: []u8 = try std.fs.cwd().readFileAlloc(allocator, filename, std.math.maxInt(usize));
    defer allocator.free(content);

    const part_one_answer = try partOne(allocator, content);
    printerr("Part One Answer: {}\n", .{part_one_answer});
}
