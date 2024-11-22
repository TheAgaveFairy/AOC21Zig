const std = @import("std");
const printerr = std.debug.print;

const N = 1000; // 1000 or so for the real run

const Direction = enum {
    horizontal,
    vertical,
    pos_diagonal, // ex 1,3 -> 2,4
    neg_diagonal, // ex 4,0 -> 2,2
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
        if (self.start.x < self.end.x) {
            if (self.start.y < self.end.y) return .pos_diagonal;
            return .neg_diagonal;
        } else {
            if (self.start.y > self.end.y) return .pos_diagonal;
            return .neg_diagonal;
        }
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
                for (start..end+1) |x| self.grid[y][x] += 1;
            },

            .vertical => {
                const x = vent.start.x;
                const start = @min(vent.start.y, vent.end.y);
                const end = @max(vent.start.y, vent.end.y);
                for (start..end+1) |y| self.grid[y][x] += 1;  
            },

            .pos_diagonal => { // comment out if you just want part one
                const startx = @min(vent.start.x, vent.end.x);
                const endx   = @max(vent.start.x, vent.end.x);
                const starty = @min(vent.start.y, vent.end.y);
                //const endy   = @max(vent.start.y, vent.end.y);
                const distance = endx - startx; // == endy - starty
                //printerr("posdiag: x{} y{} len {}\n", .{startx, starty, distance});
                for (0..distance+1) |k| {
                    self.grid[starty + k][startx + k] += 1; 
                }
            },
            
            .neg_diagonal => {
                const startx = @min(vent.start.x, vent.end.x);
                const endx   = @max(vent.start.x, vent.end.x);
                const starty = @max(vent.start.y, vent.end.y);
                const distance = endx - startx;
                //printerr("negdiag: x{} y{} len {}\n", .{startx, starty, distance});
                for (0..distance+1) |k| {
                    self.grid[starty - k][startx + k] += 1;
                }
            }
        }        
    }

    pub fn print(self: *Diagram) void {
        for (0..N) |y| { // i wasn't thinking and forgot that y moves us down the rows, x across cols
            for (0..N) |x| {
                printerr("{d:2}", .{self.grid[y][x]});
            }
            printerr("\n", .{});
        }
    }
    pub fn sumOverThreshold(self: *Diagram, threshold: usize) usize {
        var sum: usize = 0;
        for (0..N) |y| { // y moves us down the rows, x across cols
            for (0..N) |x| {
                if(self.grid[y][x] >= threshold) sum += 1;
            }
        }
        return sum;
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
        //printerr("Start: {d:3}, {d:3}. End: {d:3}, {d:3}.\n", .{start_coord.x, start_coord.y, end_coord.x, end_coord.y});
        const vent: Vent = Vent{
            .start = start_coord,
            .end = end_coord,
        };
        try vent_list.append(vent);
    }
    return vent_list;
}

fn partOne(allocator: std.mem.Allocator) !usize {
    const infilename = "../inputs/day5.txt";

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

    if (N == 10) diagram.print();
    const answer = diagram.sumOverThreshold(2);
    return answer;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const part_one_answer = try partOne(allocator);
    
    printerr("Part One Answer: tldr you ain't getting it right now! hehe\n", .{});
    printerr("Part Two Answer: {}\n", .{part_one_answer});

}
