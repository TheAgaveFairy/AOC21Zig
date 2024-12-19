const std = @import("std");
const printerr = std.debug.print;

const MAX_CAVES = 32;

const CaveType = enum { start, end, big, small };

const Cave = struct {
    name: []const u8,
    caveType: CaveType,
    paths: std.ArrayList(*Cave),
    allocator: std.mem.Allocator,
    idx: usize,

    pub fn init(allocator: std.mem.Allocator, name: []const u8, caveType: CaveType) !*Cave {
        const cave = try allocator.create(Cave);
        cave.* = .{
            .name = name,
            .caveType = caveType,
            .paths = std.ArrayList(*Cave).init(allocator),
            .allocator = allocator,
            .idx = 0, // better ways to do this im sure
        };
        return cave;
    }
    pub fn deinit(self: *Cave) void {
        self.paths.deinit();
        self.allocator.destroy(self);
    }

    pub fn fromName(allocator: std.mem.Allocator, name: []const u8) !*Cave {
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

fn parseLine(line: []u8) ?[2][]const u8 {
    var split_iter = std.mem.splitScalar(u8, line, '-');
    const left = split_iter.next().?;
    const right = split_iter.next().?;
    return .{ left, right };
}

fn caveIndexByName(caves: std.ArrayList(*Cave), name: []const u8) ?usize {
    for (caves.items, 0..) |cave, i| {
        if (std.mem.eql(u8, name, cave.name)) {
            return i;
        }
    }
    return null;
}

fn caveIndex(caves: std.ArrayList(*Cave), cave: *Cave) ?usize {
    for (caves.items, 0..) |c, i| {
        if (c == cave) return i;
    }
    return null;
}

fn traverseCaves(caves: std.ArrayList(*Cave), node: *Cave, path_visited: std.StaticBitSet(MAX_CAVES)) usize {
    var found_paths: usize = 0;
    var visited = path_visited;

    // success
    if (node.caveType == .end) {
        return 1;
    }

    // can only visit small caves once
    if (node.caveType == .small) {
        const my_idx = caveIndex(caves, node).?;
        if (visited.isSet(my_idx)) return 0;
        visited.set(my_idx);
    }

    for (node.paths.items) |next_cave| {
        if (next_cave.caveType != .start)
            found_paths += traverseCaves(caves, next_cave, visited);
    }

    return found_paths;
}

fn traverseCavesTwo(caves: std.ArrayList(*Cave), node: *Cave, path_visited: [MAX_CAVES]u2) usize {
    var found_paths: usize = 0;
    var visited = path_visited;
    const my_idx = node.idx;

    // success
    if (node.caveType == .end) {
        return 1;
    }

    // can only visit small caves once EXCEPT we're allowed to visit a single small cave TWICE
    if (node.caveType == .small) {
        visited[my_idx] += 1; // we could make this more efficient, whatever
        var twice_counter: usize = 0;
        for (0..MAX_CAVES) |i| {
            if (visited[i] == 2) twice_counter += 1;
            if (visited[i] == 3) return 0;
        }
        if (twice_counter > 1) return 0;
    }

    for (node.paths.items) |next_cave| {
        if (next_cave.caveType != .start) {
            found_paths += traverseCavesTwo(caves, next_cave, visited);
        }
    }

    return found_paths;
}

pub fn buildCaves(allocator: std.mem.Allocator, contents: []u8) !std.ArrayList(*Cave) {
    var caves = std.ArrayList(*Cave).init(allocator); // caller deinits
    var input = contents;

    while (std.mem.indexOfScalar(u8, input, '\n')) |idx| {
        const line = input[0..idx];
        const pair = parseLine(line).?;

        const left_name = pair[0];
        const right_name = pair[1];

        var left: *Cave = undefined;
        if (caveIndexByName(caves, left_name)) |left_idx| {
            left = caves.items[left_idx];
        } else {
            left = try Cave.fromName(allocator, left_name);
            try caves.append(left);
        }

        var right: *Cave = undefined;
        if (caveIndexByName(caves, right_name)) |right_idx| {
            right = caves.items[right_idx];
        } else {
            right = try Cave.fromName(allocator, right_name);
            try caves.append(right);
        }

        try left.connect(right);
        try right.connect(left);

        input = input[idx + 1 ..];
    }
    //printerr("buildCaves: caves built!\n", .{});
    for (caves.items, 0..) |c, i| {
        //printerr("{str}, ", .{c.name});
        c.idx = i;
    }
    //printerr("\n", .{});

    return caves;
}

pub fn partOne(allocator: std.mem.Allocator, contents: []u8) !usize {
    const caves = try buildCaves(allocator, contents);
    defer caves.deinit();
    defer for (caves.items) |c| c.deinit();

    var start_cave: *Cave = undefined;
    for (caves.items) |c| {
        if (c.caveType == .start) start_cave = c;
    }
    std.debug.assert(std.mem.eql(u8, start_cave.name, "start"));

    //for (start_cave.paths.items) |p| printerr("start - {str}\n", .{p.name});

    const visited = std.StaticBitSet(MAX_CAVES).initEmpty(); // could handle this any number of ways, bool ** caves.items.len, etc
    const answer = traverseCaves(caves, start_cave, visited);

    const visited_two = [_]u2{0} ** MAX_CAVES;
    //const visited_two = std.StaticBitSet(MAX_CAVES).initEmpty(); // could handle this any number of ways, bool ** caves.items.len, etc
    const answer_two = traverseCavesTwo(caves, start_cave, visited_two);
    defer printerr("Part Two: {}\n", .{answer_two});
    return answer;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const filename = "../inputs/day12.txt";
    const content: []u8 = try std.fs.cwd().readFileAlloc(allocator, filename, std.math.maxInt(usize));
    defer allocator.free(content);

    const part_one_answer = try partOne(allocator, content);
    printerr("Part One Answer: {}\n", .{part_one_answer});
}
