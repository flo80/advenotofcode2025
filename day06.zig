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

    var operation = iterators.getLast();
    while (operation.next()) |token| {
        var res = try std.fmt.parseInt(usize, iterators.items[0].next() orelse unreachable, 10);

        for (1..iterators.items.len - 1) |i| {
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
    const operator_line = lines.pop() orelse unreachable;

    var operation: u8 = ' ';
    var current_result: usize = 0;

    var offset: usize = 0;
    while (true) {
        var current_number: usize = 0;
        var empty = true;

        // parse current number vertically
        for (lines.items) |line| {
            if (offset >= line.len) continue;

            const c = line[offset];
            if (c != ' ') {
                const n: u8 = c - '0';
                empty = false;
                current_number = current_number * 10 + n;
            }
        }

        if (offset < operator_line.len) {
            const potential_operation = operator_line[offset];
            if (potential_operation != ' ') operation = potential_operation;
        }

        if (empty) {
            part_b += current_result;
            current_result = 0;
            if (offset >= operator_line.len) break;
        } else {
            switch (operation) {
                '+' => current_result += current_number,
                '*' => current_result = current_number * (if (current_result == 0) 1 else current_result),
                else => unreachable,
            }
        }

        offset += 1;
    }

    return part_b + current_result;
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
