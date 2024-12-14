const std = @import("std");
const printerr = std.debug.print;

const CaveType = enum { start, end, big, small };

const Cave = struct {
    name: []const u8,
    caveType: CaveType,
    paths: std.ArrayList(*Cave),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, name: []const u8, caveType: CaveType) !*Cave {
        const cave = try allocator.create(Cave);
        cave.* = .{
            .name = name,
            .caveType = caveType,
            .paths = std.ArrayList(*Cave).init(allocator),
            .allocator = allocator,
        };
        return cave;
    }
    pub fn deinit(self: *Cave) void {
        self.paths.deinit();
        self.allocator.destroy(self);
    }

    pub fn fromName(allocator: std.mem.Allocator, name: []const u8) !*Cave {
        //printerr("from name: {str}\n", .{name});
        if (std.ascii.eqlIgnoreCase(name, "start")) {
            return try Cave.init(allocator, name, CaveType.start);
        } else if (std.ascii.eqlIgnoreCase(name, "end")) {
            return try Cave.init(allocator, name, CaveType.end);
        } else if (name[0] < 'z' and name[0] >= 'a') {
            return try Cave.init(allocator, name, CaveType.small);
        } else if (name[0] < 'Z' and name[0] >= 'A') {
            return try Cave.init(allocator, name, CaveType.big);
        } else unreachable;
    }

    /// Unsafe, Unidirectional. I'm not checking for the case where the connection already exists. Deal with it.
    pub fn connect(self: *Cave, cave_ptr: *Cave) !void {
        try self.paths.append(cave_ptr);
    }

    pub fn pathTo(self: *Cave, other: *Cave) bool {
        for (self.paths.items) |cave_ptr| {
            if (cave_ptr == other) return true;
        }
        return false;
    }
};

pub fn parseLine(line: []u8) ?[2][]const u8 {
    var split_iter = std.mem.splitScalar(u8, line, '-');
    const left = split_iter.next().?;
    const right = split_iter.next().?;
    //printerr("left: {str}. right: {str}\n", .{ left, right });
    return .{ left, right };
}

pub fn caveIndex(caves: std.ArrayList(*Cave), name: []const u8) ?usize {
    for (caves.items, 0..) |cave, i| {
        if (std.mem.eql(u8, name, cave.name)) {
            printerr("{str} found\n", .{name});
            return i;
        }
    }
    return null;
}

pub fn buildCaves(allocator: std.mem.Allocator, contents: []u8) !*Cave {
    //var buf: [1024]u8 = undefined;
    var caves = std.ArrayList(*Cave).init(allocator);
    defer caves.deinit();
    //defer for (caves.items) |cave| cave.deinit();
    var input = contents;

    while (std.mem.indexOfScalar(u8, input, '\n')) |idx| {
        const line = input[0..idx];
        printerr("line: {str}\n", .{line});
        const pair = parseLine(line).?;

        const left_name = pair[0];
        const right_name = pair[1];

        var left: *Cave = undefined;
        if (caveIndex(caves, left_name)) |left_idx| {
            left = caves.items[left_idx];
        } else {
            left = try Cave.fromName(allocator, left_name);
            try caves.append(left);
        }

        var right: *Cave = undefined;
        if (caveIndex(caves, right_name)) |right_idx| {
            right = caves.items[right_idx];
        } else {
            right = try Cave.fromName(allocator, right_name);
            try caves.append(right);
        }

        try left.connect(right);
        try right.connect(left);

        input = input[idx + 1 ..];
    }
    for (caves.items) |c| printerr("{str}, ", .{c.name});
    printerr("\n", .{});

    const start_idx = caveIndex(caves, "start").?;
    return caves.items[start_idx];
}

pub fn partOne(allocator: std.mem.Allocator, contents: []u8) !usize {
    const start_cave = try buildCaves(allocator, contents);
    std.debug.assert(std.mem.eql(u8, start_cave.name, "start"));
    //printerr("debug: {}\n", .{start_cave.paths.len});
    for (start_cave.paths.items) |p| printerr("start - {str}\n", .{p.name});
    return 69;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const filename = "../inputs/day12test.txt";
    const content: []u8 = try std.fs.cwd().readFileAlloc(allocator, filename, std.math.maxInt(usize));
    defer allocator.free(content);

    const part_one_answer = try partOne(allocator, content);
    printerr("Part One Answer: {}\n", .{part_one_answer});
}
