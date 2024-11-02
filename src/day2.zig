const std = @import("std");
const ArrayList = std.ArrayList;
const heap = std.heap;
const printerr = std.debug.print;

const Instr = enum {
    forward,
    up,
    down,

    pub fn fromString(str: []const u8) !Instr {
        if (std.mem.eql(u8, str, "forward")) return .forward;
        if (std.mem.eql(u8, str, "up")) return .up;
        if (std.mem.eql(u8, str, "down")) return .down;
        printerr("fromString() ERROR: given {s}.\n", .{str});
        return error.InvalidInstr;
    }
};

const SubmarineTwo = struct {
    x_pos: usize = 0,
    y_pos: usize = 0,
    aim:   usize = 0,

    pub fn moveForward(self: *SubmarineTwo, value: usize) void { 
        self.x_pos += value;
        self.y_pos += self.aim * value;
    }
    pub fn moveDown(self: *SubmarineTwo, value: usize) void {
        self.aim += value;
    }
    pub fn moveUp(self: *SubmarineTwo, value: usize) void {
        self.aim -= value;
    }
};

//fn partOne(line: []const u8, 

pub fn main() !void {
    
    var file = try std.fs.cwd().openFile("../inputs/day2.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [256]u8 = undefined; //ascii bytes
    
    var x_pos:usize = 0;
    var y_pos:usize = 0;
    
    var subTwo = SubmarineTwo{};
    printerr("Submarine Two Init: {} {} {}.\n", .{subTwo.x_pos, subTwo.y_pos, subTwo.aim});

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) printerr("BAD LINE\n", .{});
        var iter = std.mem.splitScalar(u8, line, ' ');
        const instr_str = iter.first();
        const value = try std.fmt.parseInt(usize, iter.rest(), 10);
        const instr = try Instr.fromString(instr_str);
        
        switch(instr){
            .forward => {
                x_pos += value; // part one
                subTwo.moveForward(value);
            },
            .up => {
                y_pos -= value; // part one
                subTwo.moveUp(value);
            },
            .down => {
                y_pos += value; // part one
                subTwo.moveDown(value);
            }
        }
    }
    printerr("PartOne: x:{} y:{} => answer: {}.\n", .{x_pos, y_pos, x_pos * y_pos});
    printerr("PartTwo: x:{} y:{} aim:{} => answer: {}.\n", .{subTwo.x_pos, subTwo.y_pos, subTwo.aim, subTwo.y_pos * subTwo.x_pos});
}
