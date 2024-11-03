const std = @import("std");
const heap = std.heap;
const printerr = std.debug.print;

const BITS = 12;

fn lineToInteger(line: [12]u8) u32 {
    var i: u5 = 0;
    const length: u5 = line.len;
    var answer: u32 = 0;
    while (i < length) : (i +=1 ){
        if(line[i] == '1'){
            const t: u5 = length - i - @as(u5,1);
            answer += @as(u32, 1) << @as(u5,t);
        }
    }
    return answer;
}

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

    const LineBuffer = [12]u8;
    var lines = std.ArrayList(LineBuffer).init(allocator);
    defer lines.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var temp_line: LineBuffer = undefined;
        @memcpy(temp_line[0..line.len], line);
        try lines.append(temp_line);
        for (line, 0..) |byte, i| {
            if (byte == '1'){
                binaryCounts[i] += 1;
            }
        }
    }


    const totalLines = lines.items.len;
    const gamma = partOneProcessing(binaryCounts, totalLines);
    const epsilon = getInverseBinary(gamma);
    printerr("Part One: {} * {} = {}.\n", .{gamma, epsilon, gamma * epsilon});
    
    // THUS BEGAN PART TWO IN EARNEST

    var oxygen = try allocator.alloc(bool, totalLines);
    defer allocator.free(oxygen);
    for (oxygen) |*value| {
        value.* = true;
    }
    var carbon = try allocator.alloc(bool, totalLines);
    defer allocator.free(carbon);
    for (carbon) |*value| {
        value.* = true;
    }
    
 
    var oxygenEligible: usize = totalLines; //answer is when we're down to one
    var carbonEligible: usize = totalLines; //answer is when we're down to one
    const mostCommon = getMostCommonBitPerPosition(binaryCounts, totalLines); // true = 1, false = 0 
    printerr("mostCommon {any}\n.", .{mostCommon});    
    
    outer: for (mostCommon, 0..) |mc, b| {
        for (lines.items, 0..) |line, i| {
            if(oxygenEligible > 1 and oxygen[i]){
                const isOne = line[b] == '1';
                if ((isOne and !mc) or (!isOne and mc)){
                    oxygen[i] = false;
                    oxygenEligible -= 1;
                }
            }
            if(carbonEligible > 1 and carbon[i]){
                const isOne = line[b] == '1';
                if ((isOne and mc) or (!isOne and !mc)){
                    carbon[i] = false;
                    carbonEligible -= 1;
                }
            }
            if(oxygenEligible == 1 and carbonEligible == 1) break :outer;
        }
    }
    
    var oxygenIndex: usize = 0;
    var carbonIndex: usize = 0;
    for (oxygen, carbon, 0..) |o, c, i| {
        if (o) {
            oxygenIndex = i;
        }
        if (c) {
            carbonIndex = i;
        }
    }
    const finalOxygen = lineToInteger(lines.items[oxygenIndex]);
    const finalCarbon = lineToInteger(lines.items[carbonIndex]);
    const partTwoAnswer = finalOxygen * finalCarbon;
    printerr("Part Two: {}.\n", .{partTwoAnswer});
}
