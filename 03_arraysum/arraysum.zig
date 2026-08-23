const std = @import("std");

const N: u64 = 10_000_000;

pub fn main(init: std.process.Init) !void {
    const alloc = init.arena.allocator();
    const a = try alloc.alloc(u64, N);
    var i: u64 = 0;
    while (i < N) : (i += 1) {
        a[i] = i;
    }
    var sum: u64 = 0;
    for (a) |x| {
        sum += x;
    }
    var buf: [64]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &buf);
    const stdout = &stdout_writer.interface;
    try stdout.print("sum = {d}\n", .{sum});
    try stdout.flush();
}
