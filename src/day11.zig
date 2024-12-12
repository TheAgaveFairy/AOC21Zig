const std = @import("std");
const printerr = std.debug.print;

const Board = struct {
    contents: []u8,
    rows: usize,
    cols: usize,

    pub fn init(contents_in: []u8) Board {
        const cols = std.mem.indexOfScalar(u8, contents_in, '\n').? + 1;
        const rows = contents_in.len / cols;
        return Board{
            .contents = contents_in,
            .rows = rows,
            .cols = cols,
        };
    }
    pub fn deinit(self: *Board) void { // might not want to do it this way?
        self.contents.deinit();
    }
    pub fn increaseByOne(self: *Board) void {
        //printerr("board increaseByOne()\n", .{});
        for (self.contents, 0..) |c, i| {
            if (c != '\n') self.contents[i] += 1;
        }
    }
    pub fn flash(self: *Board, row: usize, col: usize) usize {
        const curr = self.charAt(row, col);
        if (curr == '\n') return 0;
        if (curr > '9') {
            //printerr("flash ({},{})\n", .{ row, col });
            self.contents[self.getIdx(row, col)] = '0';

            return 1 + self.effectNeighbors(row, col);
        } else if (curr == '0') {
            return 0; // just for clarity
        } else {
            //printerr("inc ({},{})\n", .{ row, col });
            self.contents[self.getIdx(row, col)] += 1;
        }
        return 0;
    }
    fn effectNeighbors(self: *Board, row: usize, col: usize) usize {
        var total_flashes: usize = 0;
        const r: isize = @intCast(row);
        const c: isize = @intCast(col);

        if (self.validLoc(r - 1, c - 1)) total_flashes += self.flash(row - 1, col - 1);
        if (self.validLoc(r - 1, c + 0)) total_flashes += self.flash(row - 1, col + 0);
        if (self.validLoc(r - 1, c + 1)) total_flashes += self.flash(row - 1, col + 1);

        if (self.validLoc(r + 0, c - 1)) total_flashes += self.flash(row + 0, col - 1);
        if (self.validLoc(r + 0, c + 1)) total_flashes += self.flash(row + 0, col + 1);

        if (self.validLoc(r + 1, c - 1)) total_flashes += self.flash(row + 1, col - 1);
        if (self.validLoc(r + 1, c + 0)) total_flashes += self.flash(row + 1, col + 0);
        if (self.validLoc(r + 1, c + 1)) total_flashes += self.flash(row + 1, col + 1);

        return total_flashes;
    }
    pub fn getSize(self: *Board, i: usize) .{ usize, usize } {
        const col = i / self.cols; // + 1 for '\n'
        const row = i * self.cols;
        return .{ row, col };
    }
    pub fn getIdx(self: *Board, row: usize, col: usize) usize {
        return row * self.cols + col;
    }
    pub fn validLoc(self: *Board, row: isize, col: isize) bool {
        if (row >= 0 and row < self.rows) {
            if (col >= 0 and col < self.cols) {
                return true;
            }
        }
        return false;
    }
    pub fn charAt(self: *Board, row: usize, col: usize) u8 {
        return self.contents[self.getIdx(row, col)];
    }
    pub fn print(self: *Board) void {
        for (self.contents) |c| {
            printerr("{c}", .{c});
            if (c != '\n') printerr(" ", .{});
        }
        printerr("\n", .{});
    }
};

fn processFlashes(board: *Board) usize {
    var flashes: usize = 0;

    for (board.contents, 0..) |c, i| {
        const row = i / (board.cols);
        const col = i % board.cols;
        //printerr("pF ({},{}) {c}\n", .{ row, col, c });

        if (c != '\n' and c > '9' and c != '0') {
            flashes += board.flash(row, col);
            //board.contents[i] = '0';
        }
    }
    //printerr("flashes: {}\n", .{flashes});
    return flashes;
}

fn partOne(contents: []u8) !usize {
    var total_flashes: usize = 0;

    var board = Board.init(contents);
    board.print();
    //printerr("rows {} cols {}\n", .{ board.rows, board.cols });
    for (0..100) |_| {
        board.increaseByOne();
        //board.print();
        var temp_flashes = processFlashes(&board);
        //total_flashes += temp_flashes;
        while (temp_flashes > 0) {
            total_flashes += temp_flashes;
            temp_flashes = processFlashes(&board);
        }
        //printerr("end of iteration {}\n", .{i});
        //board.print();
    }

    return total_flashes;
}
fn partTwo(contents: []u8) usize {
    var total_flashes: usize = 0;

    var board = Board.init(contents);
    const num_elements = board.rows * (board.cols - 1);
    var last_flashes: usize = 0;
    for (0..1000) |i| {
        //board.print();
        board.increaseByOne();
        var temp_flashes = processFlashes(&board);
        while (temp_flashes > 0) {
            total_flashes += temp_flashes;
            temp_flashes = processFlashes(&board);
        }
        if (last_flashes + num_elements == total_flashes) {
            //printerr("i: {}. total: {}.\n", .{ i, total_flashes });
            return i + 1; // we zero indexed so add one
        }
        last_flashes = total_flashes;
        //printerr("i: {}. total: {}.\n", .{ i, total_flashes });
    }
    return 0;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const filename = "../inputs/day11.txt";
    const content: []u8 = try std.fs.cwd().readFileAlloc(allocator, filename, std.math.maxInt(usize));
    defer allocator.free(content);

    const part_one_answer = try partOne(content);
    printerr("Part One Answer: {}\n", .{part_one_answer});
    const content_two = try std.fs.cwd().readFileAlloc(allocator, filename, std.math.maxInt(usize));
    defer allocator.free(content_two);
    const part_two_answer = partTwo(content_two);
    printerr("Part Two Answer: {}\n", .{part_two_answer});
}
