const std = @import("std");
const heap = std.heap;
const printerr = std.debug.print;

const BOARD_SIZE = 5;

const Board = struct {
    grid: [BOARD_SIZE][BOARD_SIZE]u8,
    marked: [BOARD_SIZE][BOARD_SIZE]bool = [_][BOARD_SIZE]bool{[_]bool{false} ** BOARD_SIZE} ** BOARD_SIZE,
    won: bool = false,

    pub fn checkWin(self: *Board) bool {
        for (self.marked) |row| {
            var all_marked = true;
            for (row) |cell| {
                if (!cell) {
                    all_marked = false;
                    break;
                }
            }
            if (all_marked){
                 self.won = true;
                 return true;
            }
        }

        var col: u3 = 0; // princess
        while (col < BOARD_SIZE) : (col += 1) {
            var all_marked = true;
            for (self.marked) |row| {
                if (!row[col]) {
                    all_marked = false;
                    break;
                }   
            }
            if (all_marked) {
                self.won = true;
                return true;
            }
        }
        return false;
    }

    pub fn mark(self: *Board, num: u8) void {
        for (self.grid, 0..) |row, i| {
            for (row, 0..) |_, j| {
                if (self.grid[i][j] == num) self.marked[i][j] = true;
            }
        }
    }

    pub fn calcSum(self: Board) usize {
        var sum: usize = 0;
        for (self.grid, 0..) |row, i| {
            for (row, 0..) |cell, j| {
                if (!self.marked[i][j]) sum += cell;
            }
        }
        return sum;
    }
};

fn readBoards(allocator: std.mem.Allocator, reader: anytype) !std.ArrayList(Board){
    var boards = std.ArrayList(Board).init(allocator);
    
    var buf: [64]u8 = undefined;
    while (true) {
        var board: Board = undefined;
        var row: u3 = 0; // u3 just to be a princess
        while (row < BOARD_SIZE) : (row += 1) {
            const line = try reader.readUntilDelimiterOrEof(&buf, '\n') orelse break; //catch |err| printerr("{s}\n\n", .{err});
            if (line.len == 0) continue;
            var col: u3 = 0; // slayyy
            var nums_iter = std.mem.splitScalar(u8, std.mem.trim(u8, line, " "), ' ');
            while (nums_iter.next()) |num_str| {
                if (num_str.len == 0) continue;
                board.grid[row][col] = try std.fmt.parseInt(u8, num_str, 10);
                col += 1;
            }
        }
        if (row == BOARD_SIZE) {
            try boards.append(board);
        } else {
            break;
        }
        
        _ = try reader.readUntilDelimiterOrEof(&buf, '\n'); // there's a blank line b/w boards
    }
    return boards;    
}

fn printBoards(boards: []const Board) void {
    for (boards, 0..) |board, i| {
        printerr("Board {}:\n", .{i});
        for (board.grid) |row| {
            for (row) |num| {
                printerr("{d:3}", .{num});
            }
            printerr("\n", .{});
        }
        printerr("\n", .{});
    }
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("../inputs/day4.txt", .{});
    defer file.close();

    var gpa = heap.GeneralPurposeAllocator(.{}){}; // probably fine to use page_alloc tbh but whatever
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [2048]u8 = undefined; //ascii bytes as our buffer
        
    var wheel_nums = std.ArrayList(u8).init(allocator);
    defer wheel_nums.deinit();

    const buf_slice = try in_stream.readUntilDelimiter(&buf, '\n');
    
    var wheel_iter = std.mem.splitScalar(u8, buf_slice, ',');
    while (wheel_iter.next()) |w| {
        const as_num: u8 = try std.fmt.parseInt(u8, w, 10);
        try wheel_nums.append(as_num);
        //printerr("{}, ", .{as_num});
    }
    _ = try in_stream.readUntilDelimiter(&buf, '\n');    
   
    var boards = try readBoards(allocator, in_stream);
    defer boards.deinit();

    //printBoards(boards.items);
    
    var p1_flag = true;
    var losers_left: usize = boards.items.len;
    logic: for (wheel_nums.items) |wn| { // absolutely could've done this at read time!
        for (boards.items) |*board| {
            board.mark(wn);
            if (board.checkWin()) {
                losers_left -= 1;
                if (p1_flag) {
                    const winner_sum = board.calcSum();
                    const answer = winner_sum * wn;
                    printerr("Part One Answer: {}\n", .{answer});
                    p1_flag = false;
                }
                if (losers_left == 0) {
                    const loser_sum = board.calcSum();
                    const answer = loser_sum * wn;
                    printerr("Part Two Answer: {}\n", .{answer});
                    break :logic;
                }
            }
        }
    }
}
