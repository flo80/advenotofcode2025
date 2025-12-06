const std = @import("std");
const print = std.debug.print;

fn partA(gpa: std.mem.Allocator, input: []const u8) !usize {
    var part_a: usize = 0;
    var iterators = try std.ArrayList(std.mem.TokenIterator(u8, .scalar)).initCapacity(gpa, 10);
    defer iterators.deinit(gpa);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const iter = std.mem.tokenizeScalar(u8, line, ' ');
        try iterators.append(gpa, iter);
    }

    var operation = iterators.pop() orelse unreachable;
    while (operation.next()) |token| {
        var res = try std.fmt.parseInt(usize, iterators.items[0].next() orelse unreachable, 10);

        for (1..iterators.items.len) |i| {
            const n = try std.fmt.parseInt(usize, iterators.items[i].next() orelse unreachable, 10);

            switch (token[0]) {
                '+' => res += n,
                '*' => res *= n,
                else => unreachable,
            }
        }
        part_a += res;
    }
    return part_a;
}

fn partB(gpa: std.mem.Allocator, input: []const u8) !usize {
    var part_b: usize = 0;
    var lines = try std.ArrayList([]const u8).initCapacity(gpa, 10);
    defer lines.deinit(gpa);

    var lines_iter = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines_iter.next()) |line| {
        if (line.len == 0) continue;
        try lines.append(gpa, line);
    }

    var operators = std.mem.tokenizeScalar(u8, lines.pop() orelse unreachable, ' ');

    var offset: usize = 0;
    var buf = [_]u8{0} ** 10;
    var buffer = std.ArrayList(u8).initBuffer(&(buf));

    while (operators.next()) |operation| {
        const op = operation[0];
        var current_result: usize = if (op == '+') 0 else 1;

        while (true) {
            buffer.clearRetainingCapacity();

            for (lines.items) |line| {
                if (offset >= line.len or line[offset] == ' ') continue;
                buffer.appendAssumeCapacity(line[offset]);
            }
            offset += 1;

            if (buffer.items.len > 0) {
                const nr = std.fmt.parseInt(usize, buffer.items, 10) catch unreachable;
                switch (op) {
                    '+' => current_result += nr,
                    '*' => current_result *= nr,
                    else => unreachable,
                }
            } else {
                part_b += current_result;
                break;
            }
        }
    }
    return part_b;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const gpa = general_purpose_allocator.allocator();

    var args = try std.process.argsWithAllocator(gpa);
    defer args.deinit();
    _ = args.skip();
    const file = args.next() orelse "day06.txt";

    const input = try std.fs.cwd().readFileAlloc(gpa, file, std.math.maxInt(usize));
    defer gpa.free(input);

    print("Day 06\nInput File: {s}\n", .{file});

    const part_a = try partA(gpa, input);
    const part_b = try partB(gpa, input);

    print("Part A: {d}\n", .{part_a});
    print("Part B: {d}\n", .{part_b});
}

test "day06" {
    const input = @embedFile("example.06.txt");
    const allocator = std.heap.DebugAllocator(.{}){};
    const gpa = allocator.allocator();
    defer std.testing.expect(allocator.deinit() == .ok);

    std.testing.expect(partA(gpa, input) == 4277556);
    std.testing.expect(partB(gpa, input) == 3263827);
}
