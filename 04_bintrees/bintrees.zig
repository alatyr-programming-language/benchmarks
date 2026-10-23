const std = @import("std");

const MIN_DEPTH: u6 = 4;
const MAX_DEPTH: u6 = 17;

const Node = struct {
    children: ?Children,

    const Children = struct { left: *Node, right: *Node };

    fn bottomUp(alloc: std.mem.Allocator, depth: u6) !*Node {
        const node = try alloc.create(Node);
        node.children = if (depth > 0) .{
            .left = try bottomUp(alloc, depth - 1),
            .right = try bottomUp(alloc, depth - 1),
        } else null;
        return node;
    }

    fn check(self: *const Node) u64 {
        const c = self.children orelse return 1;
        return 1 + c.left.check() + c.right.check();
    }
};

pub fn main(init: std.process.Init) !void {
    var buf: [256]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &buf);
    const stdout = &stdout_writer.interface;

    var long_arena = std.heap.ArenaAllocator.init(init.gpa);
    defer long_arena.deinit();
    var scratch = std.heap.ArenaAllocator.init(init.gpa);
    defer scratch.deinit();

    const stretch_depth = MAX_DEPTH + 1;
    const stretch = try Node.bottomUp(scratch.allocator(), stretch_depth);
    try stdout.print("stretch tree of depth {d} check {d}\n", .{ stretch_depth, stretch.check() });
    _ = scratch.reset(.retain_capacity);

    const long_lived = try Node.bottomUp(long_arena.allocator(), MAX_DEPTH);
    var depth: u6 = MIN_DEPTH;
    while (depth <= MAX_DEPTH) : (depth += 2) {
        const iterations = @as(u64, 1) << (MAX_DEPTH - depth + MIN_DEPTH);
        var total: u64 = 0;
        var i: u64 = 0;
        while (i < iterations) : (i += 1) {
            const tree = try Node.bottomUp(scratch.allocator(), depth);
            total += tree.check();
            _ = scratch.reset(.retain_capacity);
        }
        try stdout.print("{d} trees of depth {d} check {d}\n", .{ iterations, depth, total });
    }
    try stdout.print("long lived tree of depth {d} check {d}\n", .{ MAX_DEPTH, long_lived.check() });
    try stdout.flush();
}
