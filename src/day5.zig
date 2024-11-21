const std = @import("std");
const printerr = std.debug.print;

const N = 10; // 1000 or so for the real run

const Direction = enum {
    horizontal,
    vertical,
    diagonal,
};

const Coordinate = struct {
    x: usize,
    y: usize,

};
fn parseCoordinate(pair: []const u8) !Coordinate {
    var pair_iter = std.mem.splitScalar(u8, std.mem.trim(u8, pair, " "), ',');
    const x = pair_iter.next() orelse return error.InvalidFormat;
    const y = pair_iter.next() orelse return error.InvalidFormat;
    const int_x = try std.fmt.parseInt(usize, std.mem.trim(u8, x, " "), 10);
    const int_y = try std.fmt.parseInt(usize, std.mem.trim(u8, y, " "), 10);
    return Coordinate{.x = int_x, .y = int_y};
}

const Vent = struct {
    start: Coordinate,
    end: Coordinate,

    pub fn getDirection(self: Vent) Direction {
        if (self.start.x == self.end.x) return .vertical;
        if (self.start.y == self.end.y) return .horizontal;
        return .diagonal;
    }
};

const Diagram = struct {
    grid: [N][N]usize = std.mem.zeroes([N][N]usize),

    pub fn markVent(self: *Diagram, vent: Vent) void {
        const direction = vent.getDirection();
        switch (direction) {
            .horizontal => {
                const y = vent.start.y;
                const start = @min(vent.start.x, vent.end.x);
                const end = @max(vent.start.x, vent.end.x);
                for (start..end+1) |x| self.grid[x][y] += 1;
            },

            .vertical => {
                const x = vent.start.x;
                const start = @min(vent.start.y, vent.end.y);
                const end = @max(vent.start.y, vent.end.y);
                for (start..end+1) |y| self.grid[x][y] += 1;  
            },

            .diagonal => {}, // part 2
        }        
    }

    pub fn print(self: *Diagram) void {
        for (0..N) |x| {
            for (0..N) |y| {
                printerr("{d:5}", .{self.grid[x][y]});
            }
            printerr("\n", .{});
        }
    }
};

fn readVents(allocator: std.mem.Allocator, reader: anytype) !std.ArrayList(Vent) {
    var buf: [1024]u8 = undefined;
    
    var vent_list = std.ArrayList(Vent).init(allocator);

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var coords_iter = std.mem.splitSequence(u8, line, "->");
        const first_pair = coords_iter.next().?;
        const second_pair = coords_iter.next().?;
        const start_coord: Coordinate = try parseCoordinate(first_pair);
        const end_coord: Coordinate = try parseCoordinate(second_pair);
        printerr("First: {s}. Second: {s}\n", .{first_pair, second_pair});
        const vent: Vent = Vent{
            .start = start_coord,
            .end = end_coord,
        };
        try vent_list.append(vent);
    }
    return vent_list;
}

fn partOne(allocator: std.mem.Allocator) !usize {
    const infilename = "../inputs/day5test.txt";

    var infile = try std.fs.cwd().openFile(infilename, .{});
    defer infile.close();

    var buf_reader = std.io.bufferedReader(infile.reader());
    const instream = buf_reader.reader();

    
    const vent_list = try readVents(allocator, instream);
    defer _ = vent_list.deinit();
    
    var diagram = Diagram{};
    for (vent_list.items) |vent| {
        diagram.markVent(vent);    
    }

    diagram.print();
    return 69;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const part_one_answer = try partOne(allocator);
    
    printerr("Part One Answer: {}\n", .{part_one_answer});

}