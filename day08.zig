const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const Box = struct {
    x: i64,
    y: i64,
    z: i64,

    pub fn fromLine(line: []const u8) !@This() {
        var parts = std.mem.splitScalar(u8, line, ',');
        const x = try std.fmt.parseInt(i64, parts.next().?, 10);
        const y = try std.fmt.parseInt(i64, parts.next().?, 10);
        const z = try std.fmt.parseInt(i64, parts.next().?, 10);
        return .{ .x = x, .y = y, .z = z };
    }

    pub fn eql(self: @This(), other: @This()) bool {
        return self.x == other.x and self.y == other.y and self.z == other.z;
    }

    pub fn dist(self: @This(), other: @This()) u64 {
        const dx = other.x - self.x;
        const dy = other.y - self.y;
        const dz = other.z - self.z;
        return @as(u64, @intCast(dx * dx)) + @as(u64, @intCast(dy * dy)) + @as(u64, @intCast(dz * dz));
    }
};

pub fn parse(allocator: Allocator, input: []const u8) ![]const Box {
    var boxes = try std.ArrayList(Box).initCapacity(allocator, 1024);
    defer boxes.deinit(allocator);

    var lines = std.mem.splitScalar(u8, input, '\n');

    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const box = try Box.fromLine(line);
        try boxes.append(allocator, box);
    }

    return boxes.toOwnedSlice(allocator);
}

const Distance = struct {
    d: u64,
    a: u16,
    b: u16,

    fn lessThanFct(_: void, a: @This(), b: @This()) bool {
        return a.d < b.d;
    }
};

fn calculateDistances(allocator: Allocator, boxes: []const Box) ![]const Distance {
    var distances = try std.ArrayList(Distance).initCapacity(allocator, 1024 * 1024);
    defer distances.deinit(allocator);

    var a: u16 = 0;
    while (a < boxes.len) : (a += 1) {
        var b: u16 = a + 1;
        while (b < boxes.len) : (b += 1) {
            const d = boxes[a].dist(boxes[b]);
            try distances.append(allocator, .{ .d = d, .a = a, .b = b });
        }
    }

    std.mem.sortUnstable(Distance, distances.items, {}, Distance.lessThanFct);
    return distances.toOwnedSlice(allocator);
}

fn calculateCircuitCount(allocator: Allocator, circuits_for_box: []usize) !usize {
    var circuit_counts = try std.ArrayList(usize).initCapacity(allocator, circuits_for_box.len);
    defer circuit_counts.deinit(allocator);

    circuit_counts.appendNTimesAssumeCapacity(0, circuits_for_box.len);

    for (circuits_for_box) |circuit| {
        circuit_counts.items[circuit] += 1;
    }

    std.mem.sortUnstable(usize, circuit_counts.items, {}, std.sort.desc(usize));

    return circuit_counts.items[0] * circuit_counts.items[1] * circuit_counts.items[2];
}

fn solve(allocator: Allocator, boxes: []const Box, max_conn: usize) !struct { part_a: usize, part_b: i64 } {
    var part_a: usize = undefined;

    const distances = try calculateDistances(allocator, boxes);
    defer allocator.free(distances);

    var circuits_for_box = try std.ArrayList(usize).initCapacity(allocator, boxes.len);
    defer circuits_for_box.deinit(allocator);

    for (0..boxes.len) |i| {
        try circuits_for_box.append(allocator, i);
    }

    for (0..distances.len) |i| {
        const box_a_index = distances[i].a;
        const box_b_index = distances[i].b;

        const box_a_circuit = &circuits_for_box.items[box_a_index];
        const box_b_circuit = &circuits_for_box.items[box_b_index];

        if (box_a_circuit.* != box_b_circuit.*) {
            const new_circuit = @min(box_a_circuit.*, box_b_circuit.*);
            const old_id_to_change = if (new_circuit == box_a_circuit.*) box_b_circuit.* else box_a_circuit.*;

            for (0..boxes.len) |c| {
                if (circuits_for_box.items[c] != old_id_to_change) continue;
                circuits_for_box.items[c] = new_circuit;
            }
        }

        if (i == max_conn - 1) part_a = try calculateCircuitCount(allocator, circuits_for_box.items);

        if (std.mem.allEqual(usize, circuits_for_box.items, circuits_for_box.items[0])) {
            const box_a = boxes[box_a_index];
            const box_b = boxes[box_b_index];

            return .{
                .part_a = part_a,
                .part_b = box_a.x * box_b.x,
            };
        }
    }
    unreachable;
}

fn partA(allocator: Allocator, boxes: []const Box, max_conn: usize) !usize {
    return (try solve(allocator, boxes, max_conn)).part_a;
}

fn partB(allocator: Allocator, boxes: []const Box) !i64 {
    return (try solve(allocator, boxes, undefined)).part_b;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const gpa = general_purpose_allocator.allocator();

    var args = try std.process.argsWithAllocator(gpa);
    defer args.deinit();
    _ = args.skip();
    const file = args.next() orelse "day08.txt";

    const count_text = args.next() orelse "1000";
    const count = try std.fmt.parseInt(usize, count_text, 10);

    const input = try std.fs.cwd().readFileAlloc(gpa, file, std.math.maxInt(usize));
    defer gpa.free(input);

    print("Day 08\nInput File: {s}\n", .{file});
    const boxes = try parse(gpa, input);
    defer gpa.free(boxes);

    const result = try solve(gpa, boxes, count);

    print("Part A: {d}\n", .{result.part_a});
    print("Part B: {d}\n", .{result.part_b});
}

test "day08" {
    const input = @embedFile("example08.txt");
    var allocator = std.heap.DebugAllocator(.{}){};
    const gpa = allocator.allocator();

    const boxes = try parse(gpa, input);
    defer gpa.free(boxes);

    const result = try solve(gpa, boxes, 10);
    try std.testing.expectEqual(40, result.part_a);
    try std.testing.expectEqual(25272, result.part_b);
}
