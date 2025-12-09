const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const Point = struct {
    x: i64,
    y: i64,

    pub fn fromLine(line: []const u8) !@This() {
        var parts = std.mem.splitScalar(u8, line, ',');
        const x = try std.fmt.parseInt(i64, parts.next().?, 10);
        const y = try std.fmt.parseInt(i64, parts.next().?, 10);

        return .{ .x = x, .y = y };
    }

    pub fn area(self: @This(), other: @This()) u64 {
        const dx = @abs(other.x - self.x) + 1;
        const dy = @abs(other.y - self.y) + 1;

        return dx * dy;
    }
};

pub fn parse(allocator: Allocator, input: []const u8) ![]const Point {
    var points = try std.ArrayList(Point).initCapacity(allocator, 1024);
    defer points.deinit(allocator);

    var lines = std.mem.splitScalar(u8, input, '\n');

    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const box = try Point.fromLine(line);
        try points.append(allocator, box);
    }

    return points.toOwnedSlice(allocator);
}

fn partA(points: []const Point) !usize {
    var max: u64 = 0;

    var i: usize = 0;
    while (i < points.len) : (i += 1) {
        var j: usize = i + 1;
        while (j < points.len) : (j += 1) {
            const area = points[i].area(points[j]);
            max = @max(area, max);
        }
    }

    return max;
}

fn partB(allocator: Allocator, points: []const Point) !u64 {
    const Edge = struct {
        left: i64,
        right: i64,
        top: i64,
        bottom: i64,

        fn fromPoints(a: Point, b: Point) @This() {
            return .{
                .left = @min(a.x, b.x),
                .right = @max(a.x, b.x),
                .top = @min(a.y, b.y),
                .bottom = @max(a.y, b.y),
            };
        }
    };

    const Rect = struct {
        left: i64,
        right: i64,
        top: i64,
        bottom: i64,

        area: u64,

        fn fromPoints(a: Point, b: Point) @This() {
            return .{
                .left = @min(a.x, b.x),
                .right = @max(a.x, b.x),
                .top = @min(a.y, b.y),
                .bottom = @max(a.y, b.y),
                .area = a.area(b),
            };
        }

        fn largerThan(_: void, self: @This(), other: @This()) bool {
            return self.area > other.area;
        }

        fn notCrossing(rect: @This(), edge: Edge) bool {
            return rect.right <= edge.left or
                rect.left >= edge.right or
                rect.bottom <= edge.top or
                rect.top >= edge.bottom;
        }
    };

    var edges = try std.ArrayList(Edge).initCapacity(allocator, 1024);
    defer edges.deinit(allocator);

    for (0..points.len) |i| {
        try edges.append(allocator, Edge.fromPoints(points[i], points[(i + 1) % points.len]));
    }

    var possible_rects = try std.ArrayList(Rect).initCapacity(allocator, 1024);
    defer possible_rects.deinit(allocator);

    for (0..points.len - 1) |i| {
        for (i + 1..points.len) |j| {
            try possible_rects.append(allocator, Rect.fromPoints(points[i], points[j]));
        }
    }

    std.mem.sortUnstable(Rect, possible_rects.items, {}, Rect.largerThan);

    check_rect: for (possible_rects.items) |rect| {
        for (edges.items) |edge| {
            const inside = rect.notCrossing(edge);
            if (!inside) continue :check_rect;
        }

        return rect.area;
    }

    unreachable;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const gpa = general_purpose_allocator.allocator();

    var args = try std.process.argsWithAllocator(gpa);
    defer args.deinit();
    _ = args.skip();
    const file = args.next() orelse "day09.txt";

    const input = try std.fs.cwd().readFileAlloc(gpa, file, std.math.maxInt(usize));
    defer gpa.free(input);

    print("Day 09\nInput File: {s}\n", .{file});
    const points = try parse(gpa, input);
    defer gpa.free(points);

    const part_a = try partA(points);
    const part_b = try partB(gpa, points);

    print("Part A: {d}\n", .{part_a});
    print("Part B: {d}\n", .{part_b});
}

test "day09" {
    const input = @embedFile("example09.txt");
    var allocator = std.heap.DebugAllocator(.{}){};
    const gpa = allocator.allocator();

    const points = try parse(gpa, input);
    defer gpa.free(points);

    try std.testing.expectEqual(50, partA(points));
    try std.testing.expectEqual(24, partB(gpa, points));
}
