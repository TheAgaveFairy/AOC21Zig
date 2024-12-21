const std = @import("std");
const printerr = std.debug.print;

const Fold = struct {
    axis: u8,
    val: usize,
};

const Setup = struct {
    width: usize,
    height: usize,
    folds: std.ArrayList(Fold),

    pub fn init(allocator: std.mem.Allocator, w: usize, h: usize) !Setup {
        return .{
            .width = w,
            .height = h,
            .folds = std.ArrayList(Fold).init(allocator),
        };
    }
    pub fn deinit(self: *Setup) void {
        self.folds.deinit();
    }
    fn addFold(self: *Setup, axis: u8, val: usize) !void {
        try self.folds.append(.{ .axis = axis, .val = val });
    }
    pub fn preProcess(allocator: std.mem.Allocator, in_contents: []u8) !Setup {
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

        var setup = try Setup.init(allocator, w + 1, h + 1);
        while (std.mem.indexOfScalar(u8, contents, '\n')) |newl| {
            const line = contents[0..newl];

            if (line.len < 2) {
                if (newl == 0) contents = contents[1..];
                continue;
            }
            var split_iter = std.mem.splitScalar(u8, line, '=');
            const left = split_iter.next().?;
            const right = split_iter.next().?;

            const fold_axis = left[left.len - 1];
            const fold_line_num = try std.fmt.parseInt(usize, right, 10);
            //printerr("fold ready: {c}-axis {}\n", .{ fold_axis, fold_line_num });

            try setup.addFold(fold_axis, fold_line_num);
            contents = contents[newl + 1 ..];
        }
        return setup;
    }
};

const Sheet = struct {
    data: []bool,
    width: usize,
    height: usize,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, w: usize, h: usize) !Sheet {
        const data = try allocator.alloc(bool, w * h);
        @memset(data, false);
        return .{ .data = data, .width = w, .height = h, .allocator = allocator };
    }
    pub fn deinit(self: *Sheet) void {
        self.allocator.free(self.data);
    }

    fn set(self: *Sheet, x: usize, y: usize, val: bool) void {
        self.data[y * self.width + x] = val;
    }

    fn get(self: *Sheet, x: usize, y: usize) bool {
        return self.data[y * self.width + x];
    }

    pub fn countDots(self: *Sheet) usize {
        var answer: usize = 0;
        for (self.data) |d| {
            if (d) answer += 1;
        }
        return answer;
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
        printerr("Sheet Size: {}, {}.\n", .{ self.width, self.height });
        for (self.data, 0..) |b, i| {
            if (i > 0 and i % self.width == 0) printerr("\n", .{});
            const p: u8 = if (b) '#' else '.';
            printerr("{c}", .{p});
        }
        printerr("\n", .{});
    }

    /// deinits the sheet and returns a new one with a smaller size and updated dots
    pub fn foldY(self: *Sheet, y: usize) !Sheet {
        defer self.deinit();
        var idx: usize = 0;
        var i: usize = 0; // "x"
        var j: usize = 0; // "y"

        var new_sheet = try Sheet.init(self.allocator, self.width, y);

        while (idx < (y * self.width)) {
            i = idx % self.width;
            j = idx / self.width;
            const folded_row = 2 * y - j;
            if (folded_row >= self.height) {
                new_sheet.set(i, j, self.get(i, j));
                idx += 1;
                continue;
            }
            //printerr("idx{} -> x{},y{}/{}. {} / {}.\n", .{ idx, i, j, folded_row, self.get(i, j), self.get(i, folded_row) });
            const b = self.get(i, j) or self.get(i, folded_row);
            new_sheet.set(i, j, b);
            idx += 1;
        }
        return new_sheet;
    }

    /// deinits the sheet and returns a new one with a smaller size and updated dots
    pub fn foldX(self: *Sheet, x: usize) !Sheet {
        defer self.deinit();
        var idx: usize = 0;
        var i: usize = 0;
        var j: usize = 0;

        var new_sheet = try Sheet.init(self.allocator, x, self.height);
        while (idx < self.data.len - 1) {
            i = idx % self.width;
            j = idx / self.width;
            if (i >= x) {
                idx += 1;
                continue;
            }
            const fold_x = 2 * x - i;
            if (fold_x >= self.width) {
                new_sheet.set(i, j, self.get(i, j));
                idx += 1;
                continue;
            }
            const b = self.data[idx] or self.get(fold_x, j);
            new_sheet.set(i, j, b);
            idx += 1;
        }
        return new_sheet;
    }
};

pub fn partOne(allocator: std.mem.Allocator, contents: []u8) !usize {
    var setup = try Setup.preProcess(allocator, contents);
    defer setup.deinit();
    const w = setup.width;
    const h = setup.height;

    var sheet = try Sheet.init(allocator, w, h);
    defer sheet.deinit();

    try sheet.process(contents);
    //sheet.print();

    const fold = setup.folds.items[0];
    //for (setup.folds.items) |fold| {
    if (sheet.width < 10) sheet.print();
    printerr("fold: {c} {}\n", .{ fold.axis, fold.val });
    sheet = switch (fold.axis) {
        'x' => try sheet.foldX(fold.val),
        'y' => try sheet.foldY(fold.val),
        else => unreachable,
    };
    //}
    if (sheet.width < 10) sheet.print();

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
