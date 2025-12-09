const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    var dir = try std.fs.cwd().openDir(".", .{ .iterate = true });
    defer dir.close();

    var contents = dir.iterate();
    while (contents.next() catch |err| {
        std.debug.print("Error iterating files: {any}\n", .{err});
        return;
    }) |entry| {
        if (entry.kind != .file) continue;

        if (std.mem.startsWith(u8, entry.name, "day") and
            std.mem.endsWith(u8, entry.name, ".zig"))
        {
            std.debug.print("Found {s}\n", .{entry.name});

            const exe_name = entry.name[0 .. entry.name.len - 4];

            const exe = b.addExecutable(.{
                .name = exe_name,
                .root_module = b.createModule(.{
                    .root_source_file = b.path(entry.name),
                    .target = target,
                    .optimize = .ReleaseFast,
                }),
            });

            b.installArtifact(exe);
        }

        if (std.mem.endsWith(u8, entry.name, ".txt")) {
            std.debug.print("Found {s}\n", .{entry.name});

            const copy = b.addInstallBinFile(.{ .cwd_relative = entry.name }, entry.name);
            b.getInstallStep().dependOn(&copy.step);
        }
    }
}
