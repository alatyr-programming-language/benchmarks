const std = @import("std");

const W: usize = 1024;
const H: usize = 1024;
const PASSES: u32 = 100;

fn blur(src: []const u32, dst: []u32) void {
    for (0..H) |y| {
        const y0 = if (y > 0) y - 1 else 0;
        const y1 = @min(y + 1, H - 1);
        for (0..W) |x| {
            const x0 = if (x > 0) x - 1 else 0;
            const x1 = @min(x + 1, W - 1);
            const sum = src[y0 * W + x0] + src[y0 * W + x] + src[y0 * W + x1] +
                src[y * W + x0] + src[y * W + x] + src[y * W + x1] +
                src[y1 * W + x0] + src[y1 * W + x] + src[y1 * W + x1];
            dst[y * W + x] = sum / 9;
        }
    }
}

pub fn main(init: std.process.Init) !void {
    const alloc = init.gpa;
    var a = try alloc.alloc(u32, W * H);
    defer alloc.free(a);
    var b = try alloc.alloc(u32, W * H);
    defer alloc.free(b);

    var state: u64 = 42;
    for (a) |*p| {
        state = state * 48271 % 2147483647;
        p.* = @intCast(state % 256);
    }
    for (0..PASSES) |_| {
        blur(a, b);
        std.mem.swap([]u32, &a, &b);
    }
    var sum: u64 = 0;
    for (a) |p| {
        sum += p;
    }

    var buf: [64]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &buf);
    const stdout = &stdout_writer.interface;
    try stdout.print("sum = {d}\n", .{sum});
    try stdout.flush();
}
