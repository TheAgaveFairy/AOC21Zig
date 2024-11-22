const std = @import("std");
const printerr = std.debug.print;

fn partOne(allocator: std.mem.Allocator) !usize {
    const infilename = "../inputs/day6test.txt";
    var infile = try std.fs.cwd().openFile(infilename, .{});
    defer infile.close();

    var buf_reader = std.io.bufferedReader(infile.reader());
    const instream = buf_reader.reader();

    var initial_list = std.ArrayList(usize).init(allocator);
    defer initial_list.deinit();

    var buf: [1024]u8 = undefined;
    const line = try instream.readUntilDelimiterOrEof(&buf, '\n');
    const trimmed_line = std.mem.trim(u8, line, " ");

    var input_iter = try std.mem.splitScalar(u8, trimmed_line, ',');
    while (input_iter.next()) printerr("{d:3}", .{});

    return 69;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const part_one_answer = try partOne(allocator);
    
    printerr("Part One Answer: {}\n", .{part_one_answer});

}
