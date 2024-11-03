const std = @import("std");
const heap = std.heap;
const printerr = std.debug.print;

const BITS = 5; //5 for day3test.txt

fn lineToInteger(line: [BITS]u8) u32 {
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
    const threshold = totalLines / 2;    
    var i: u5 = 0;
    
    for (binaryCounts) |bin| {
        if (bin > threshold){
            const t: u5 = @as(u5, BITS) - i - 1;
            gamma += @as(u32,1) << t;
        }
        i += 1;
    }
    return gamma;
}

fn getInverseBinary(gamma: u32) u32 {
    const mask = (@as(u32,1) << BITS) - 1;
    return (~gamma & mask); // it's so nice to have bitwise operators! XOR ^
}

fn getMostCommonBitPerPosition(binaryCounts: [BITS]usize, totalLines: usize) [BITS]bool {
    var mostCommon = [_]bool{false} ** BITS;
    const threshold = totalLines / 2;
    for (binaryCounts, 0..) |count, i| {
        if (count >= threshold) {
            mostCommon[i] = true;
        }
    }
    return mostCommon;
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("../inputs/day3test.txt", .{});
    defer file.close();

    var gpa = heap.GeneralPurposeAllocator(.{}){}; // probably fine to use page_alloc tbh but whatever
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [256]u8 = undefined; //ascii bytes as our buffer
        
    var binaryCounts = [_]usize{0} ** BITS;

    const LineBuffer = [BITS]u8;
    var lines = std.ArrayList(LineBuffer).init(allocator);
    defer lines.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var temp_line: LineBuffer = undefined;
        @memcpy(temp_line[0..BITS], line);
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
    printerr("Part One {} lines: {} * {} = {}.\n", .{totalLines, gamma, epsilon, gamma * epsilon});
    
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
    
    var oxygenEligible: usize = totalLines; // answer is when we're down to one
    var carbonEligible: usize = totalLines; // 
    var oxyThresh = oxygenEligible / 2;     // must be over this
    var carThresh = carbonEligible / 2;     // 
    for (0..BITS) |b| {
        var oxyLinesCount: usize = 0;
        var carLinesCount: usize = 0;
        var oxyOnes: usize = 0;
        var carOnes: usize = 0;
        for (lines.items, 0..) |line, i|{
            if(oxygen[i]) {
                oxyLinesCount += 1;
                if(line[b] == '1'){
                    oxyOnes += 1;
                }
            }
            if(carbon[i]) {
                carLinesCount += 1;
                if(line[b] == '1'){
                    carOnes += 1;
                }
            }
        }
        oxyThresh = oxyLinesCount / 2;
        carThresh = carLinesCount / 2;
        const mostCommonOxy: u8 = if(oxyOnes > oxyThresh or (oxyOnes == oxyThresh and oxyThresh % 2 == 0)) '1' else '0';
        const lessCommonCar: u8 = if(mostCommonOxy == '1') '0' else '1';
        printerr("Thresholds: {} and {}\n", .{oxyThresh, carThresh});
        for (lines.items, 0..) |line, i|{
            if(oxygenEligible > 1 and oxygen[i]){
                if(line[b] == mostCommonOxy){
                    oxyLinesCount += 1;
                } else {
                    oxygenEligible -= 1;
                    oxygen[i] = false;
                }
            }
            if(carbonEligible > 1 and carbon[i]){
                if(line[b] == lessCommonCar){
                    carLinesCount += 1;
                } else {
                    carbonEligible -= 1;
                    carbon[i] = false;
                }
            }
            if(oxygen[i] or true) printerr("{}\t{s} O{} C{}\n", .{i, line, oxygen[i], carbon[i]});
            if(oxygenEligible == 1 and carbonEligible == 1) break;
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

    const oxygenLine = lines.items[oxygenIndex];
    const carbonLine = lines.items[carbonIndex];
    //printerr("OL: {any} C: {any}\n", .{oxygenLine, carbonLine});

    const oxygenAns = lineToInteger(oxygenLine);
    const carbonAns = lineToInteger(carbonLine);
    printerr("O: {} C: {}\n", .{oxygenAns, carbonAns});
    const partTwoAnswer = oxygenAns * carbonAns;
    printerr("Part Two: {}.\n", .{partTwoAnswer});
}
