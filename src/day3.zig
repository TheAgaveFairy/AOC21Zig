const std = @import("std");
const heap = std.heap;
const printerr = std.debug.print;

fn partOneProcessing(binaryCounts: [12]usize, totalLines: usize) u32 {
    var gamma: u32 = 0;
    var epsilon: u32 = 0;
    const threshold = totalLines / 2;    

    for (binaryCounts, 0..) |bin, i| {
        if (bin > threshold){
            gamma += 1 << i;
        } else {
            epsilon += 1 << i;
        }
    }
    return gamma * epsilon;
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("../inputs/day3.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [256]u8 = undefined; //ascii bytes as our buffer
        
    var binaryCounts = [_]usize{0} ** 12;
    var totalLines: usize = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        //printerr("line: {s} => ", .{line});
        for (line, 0..) |byte, i| {
            //printerr("{} ", .{byte});
            if (byte == '1'){
                binaryCounts[i] += 1;
            }
        }
        totalLines += 1;
        //printerr("\n", .{});
    }
    printerr("{any} and {any}.\n", .{binaryCounts, totalLines});
    const answer = partOneProcessing(binaryCounts, totalLines);
    printerr("Part One: {}.\n", .{answer});
} 
