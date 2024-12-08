const std = @import("std");
const printerr = std.debug.print;

const Board = struct {
    contents: []u8,
    rows: usize,
    cols: usize,

    pub fn init(contents_in: []u8) Board {
        const cols = std.mem.indexOfScalar(u8, contents_in, '\n').?;
        const rows = contents_in.len / cols - 1;
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
        for (self.contents, 0..) |c, i| {
            if (c != '\n') self.contents[i] += 1;
        }
    }
    pub fn flash(self: *Board, row: usize, col: usize) usize {
        if (self.contents[self.getIdx(row, col)] > '9') {
            self.contents[self.getIdx(row, col)] = '0';
            self.effectNeighbors(self, row, col);
            return 0;
        }
        return 1;
    }
    fn effectNeighbors(self: *Board, row: usize, col: usize) usize {
        var total_flashes: usize = 0;
        if (self.validLoc(row - 1, col - 1)) total_flashes += self.flash(row - 1, col - 1);
    }
    pub fn getRowCol(self: *Board, i: usize) .{ usize, usize } {
        const col = i / self.cols;
        const row = i * self.cols;
        return .{ row, col };
    }
    pub fn getIdx(self: *Board, row: usize, col: usize) usize {
        return row * self.cols + col;
    }
    pub fn validLoc(self: *Board, row: usize, col: usize) bool {
        if (row >= 0 and row < self.rows) {
            if (col >= 0 and col < self.cols) {
                return true;
            }
        }
        return false;
    }
    pub fn print(self: *Board) void {
        for (self.contents) |c| {
            printerr("{c}", .{c});
            if (c != '\n') printerr(" ", .{});
        }
    }
};

fn effectNeighbors(board: *Board, row: usize, col: usize) void {
    board.contents[board.getIdx(row + rm, col + cm)] += 1;
}

fn processFlashes(board: *Board) usize {
    var flashes: usize = 0;

    for (board.contents, 0..) |c, i| {
        const row = i / board.cols;
        const col = i % board.cols;
        if (c != '\n' and c > '9' and c != '0') {
            flashes += 1;
            effectNeighbors(board, row, col);
            board.contents[i] = '0';
        }
    }
    return flashes;
}

fn partOne(contents: []u8) !usize {
    var total_flashes: usize = 0;

    var board = Board.init(contents);
    board.print();
    printerr("rows {} cols {}\n", .{ board.rows, board.cols });
    for (0..2) |_| {
        board.increaseByOne();
        total_flashes += processFlashes(&board);
        board.print();
    }

    return total_flashes;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const filename = "../inputs/day11test.txt";
    const content: []u8 = try std.fs.cwd().readFileAlloc(allocator, filename, std.math.maxInt(usize));
    defer allocator.free(content);

    const part_one_answer = try partOne(content);
    printerr("Part One Answer: {}\n", .{part_one_answer});
    //const part_two_answer = try partTwo(allocator, content);
    //printerr("Part Two Answer: {}\n", .{part_two_answer});
}
