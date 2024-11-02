const std = @import("std");
const heap = std.heap;
const printerr = std.debug.print;

const BITS = 12;

fn partOneProcessing(binaryCounts: [BITS]usize, totalLines: usize) u32 {
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
    return gamma;
}

fn getInverseBinary(gamma: u32) u32 {
    const mask = (@as(u32,1) << BITS) - 1;  // 12 is a magic number because each line is 12 bits. not ideal.
    printerr("not gamma {}", .{~gamma});
    return (~gamma & mask); // it's so nice to have bitwise operators!
}

fn getMostCommonBitPerPosition(binaryCounts: [BITS]usize, totalLines: usize) [BITS]bool {
    var mostCommon = [_]bool{false} ** BITS;
    const threshold = totalLines / 2;
    for (binaryCounts, 0..) |count, i| {
        if (count > threshold) {
            mostCommon[i] = true;
        }
    }
    printerr("mostCommon: {any}.\n", .{mostCommon});
    return mostCommon;
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("../inputs/day3.txt", .{});
    defer file.close();

    var gpa = heap.GeneralPurposeAllocator(.{}){}; // probably fine to use page_alloc tbh but whatever
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [256]u8 = undefined; //ascii bytes as our buffer
        
    var binaryCounts = [_]usize{0} ** BITS;
    var totalLines: usize = 0;

    var lines = std.ArrayList([]u8).init(allocator);
    defer lines.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const temp_line = line[0..BITS].toOwnedSlice();
        try lines.appendSlice(temp_line.*);
        for (line, 0..) |byte, i| {
            if (byte == '1'){
                binaryCounts[i] += 1;
            }
        }
        totalLines += 1;
    }
    printerr("{any} and {any}.\n", .{binaryCounts, totalLines});
    const gamma = partOneProcessing(binaryCounts, totalLines);
    const epsilon = getInverseBinary(gamma);
    printerr("Part One: {} * {} = {}.\n", .{gamma, epsilon, gamma * epsilon});
    
    // THUS BEGAN PART TWO IN EARNEST

    var eligible = try allocator.alloc(bool, totalLines);
    defer allocator.free(eligible);
    for (eligible) |*value| {
        value.* = true;
    }
    
    var totalEligible: usize = totalLines; //answer is when we're down to one
    const mostCommon = getMostCommonBitPerPosition(binaryCounts, totalLines); // true = 1, false = 0 
    
    for (lines.items, 0..) |line, i| {
        for (line, 0..) |charbit, b| {
            const isOne = charbit == '1';
            if ((isOne and mostCommon[b]) or (!isOne and !mostCommon[b])){
                eligible[i] = false;
                totalEligible -= 1;
                break;
            }
        }
        if (totalEligible == 1){
            printerr("DOWN TO ONE ANSWER!\n", .{});
            break;
        }
    }
    var finalIndex: usize = 0;
    for (eligible, 0..) |e, i| {
        if (e) {
            finalIndex = i;
        }
    }
    printerr("Final index: {}.\n", .{finalIndex});

}
