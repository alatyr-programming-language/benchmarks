const std = @import("std");

const LIMIT: u64 = 1_000_000;

fn isPrime(n: u64) bool {
    if (n < 2) {
        return false;
    }
    var j: u64 = 2;
    while (j * j <= n) : (j += 1) {
        if (n % j == 0) {
            return false;
        }
    }
    return true;
}

pub fn main(init: std.process.Init) !void {
    var count: u64 = 0;
    var i: u64 = 2;
    while (i < LIMIT) : (i += 1) {
        if (isPrime(i)) {
            count += 1;
        }
    }
    var buf: [64]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &buf);
    const stdout = &stdout_writer.interface;
    try stdout.print("primes = {d}\n", .{count});
    try stdout.flush();
}
