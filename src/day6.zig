const std = @import("std");
const printerr = std.debug.print;

const Fish = struct {
    time: u8,
    new: bool,
};

fn readFile(allocator: std.mem.Allocator) !std.ArrayList(u8) {
    const infilename = "../inputs/day6.txt";
    var infile = try std.fs.cwd().openFile(infilename, .{});
    defer infile.close();

    var buf_reader = std.io.bufferedReader(infile.reader());
    const instream = buf_reader.reader();

    var fishes = std.ArrayList(u8).init(allocator);

    var buf: [1024]u8 = undefined;
    const line = try instream.readUntilDelimiterOrEof(&buf, '\n') orelse unreachable;
    const trimmed_line = std.mem.trim(u8, line, " ");

    var input_iter = std.mem.splitScalar(u8, trimmed_line, ',');
    while (input_iter.next()) |numstr| {
        const num = try std.fmt.parseInt(u8, numstr, 10);
        try fishes.append(num);
    }

    return fishes;
}

fn partOne(allocator: std.mem.Allocator, days: usize) !usize {
    var fishes = try readFile(allocator);
    defer fishes.deinit();
    
    for (0..days) |_| {
        var fish_to_add: usize = 0;
        for (fishes.items, 0..) |fish, i|{
            if (fish == 0) {
                fish_to_add += 1;
                fishes.items[i] = 7; // 7 - 1
            }
            fishes.items[i] -= 1;
        }
        for (0..fish_to_add) |_| try fishes.append(8);
    } 

    return fishes.items.len;
}

fn partTwo(allocator: std.mem.Allocator) !usize {
    var tracker = [_]usize{0} ** 9;

    const fishes = try readFile(allocator);
    defer fishes.deinit();
    
    for (fishes.items) |fish| {
        tracker[fish] += 1;
    }
    for (0..256) |_| {
        const total_fish_to_add: usize = tracker[0];
        for (0..9-1) |i| {
            tracker[i] = tracker[i+1]; // shift the buffer left
        }
        tracker[8] = total_fish_to_add;
        tracker[6] += total_fish_to_add;    
    }

    var sum_of_fish: usize = 0;
    for (tracker) |count| sum_of_fish += count;
    return sum_of_fish;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const part_one_answer = try partOne(allocator, 80);
    printerr("Part One Answer: {}\n", .{part_one_answer});
    const part_two_answer = try partTwo(allocator);
    printerr("Part Two Answer: {}\n", .{part_two_answer});

}
