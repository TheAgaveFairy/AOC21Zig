const std = @import("std");
const heap = std.heap;
const printerr = std.debug.print;

fn partOneProcessing(binaryCounts: [12]usize, totalLines: usize) u32 {
    var gamma: u32 = 0;
    var epsilon: u32 = 0;
    const threshold = totalLines / 2;    

    for (binaryCounts, 0..) |bin, i| {
        const shift: u5 = @intCast(i);
        if (bin > threshold){
            gamma += @as(u32,1) << shift;
        } else {
            epsilon += @as(u32,1) << shift;
        }
    }
    printerr("p1p: G: {}, E: {}. Answer: {}.\n", .{gamma, epsilon, gamma * epsilon});
    //return gamma * epsilon;
    return gamma;
}

fn getInverseBinary(gamma: u32) u32 {
    var gamma_var = gamma;
    var epsilon: u32 = 0;
    var b: u5 = 0;
    while (gamma_var > 0){
        const lsb = gamma_var % 2;
        if (lsb == 0){
            epsilon += @as(u32,1) << b;
        } 
        gamma_var /= 2;
        b += 1;
    }
    return epsilon;
}

fn partTwo(binaryCounts: [12]usize, totalLines: usize) usize {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
 
    var candidates = std.ArrayList([12]u8).init(allocator);
    defer candidates.deinit();
    _ = binaryCounts;
    _ = totalLines;
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
    const gamma = partOneProcessing(binaryCounts, totalLines);
    const epsilon = getInverseBinary(gamma);
    printerr("Part One: {} * {} = {}.\n", .{gamma, epsilon, gamma * epsilon});
} 
