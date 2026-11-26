const std = @import("std");

const MASK: u64 = 0xF_FFFF;
const MAX_DEPTH: u32 = 12;
const RUNS: u64 = 40_000;

const Bin = struct { lhs: u32, rhs: u32 };

const Expr = union(enum) {
    constant: u64,
    variable: u32,
    add: Bin,
    sub: Bin,
    mul: Bin,
    lt: Bin,
    branch: struct { cond: u32, then: u32, other: u32 },
};

const Gen = struct {
    state: u64,
    program: std.ArrayList(Expr),
    alloc: std.mem.Allocator,

    fn next(self: *Gen) u64 {
        self.state = self.state * 48271 % 2147483647;
        return self.state;
    }

    fn gen(self: *Gen, depth: u32) !u32 {
        const r = self.next() % 10;
        var expr: Expr = undefined;
        if (depth == 0 or r < 2) {
            if (self.next() % 2 == 0) {
                expr = .{ .constant = self.next() % 100 };
            } else {
                expr = .{ .variable = @intCast(self.next() % 4) };
            }
        } else if (r < 8) {
            const b = Bin{ .lhs = try self.gen(depth - 1), .rhs = try self.gen(depth - 1) };
            expr = switch (r) {
                2, 3 => .{ .add = b },
                4 => .{ .sub = b },
                5, 6 => .{ .mul = b },
                else => .{ .lt = b },
            };
        } else {
            const cond = try self.gen(depth - 1);
            const then = try self.gen(depth - 1);
            const other = try self.gen(depth - 1);
            expr = .{ .branch = .{ .cond = cond, .then = then, .other = other } };
        }
        try self.program.append(self.alloc, expr);
        return @intCast(self.program.items.len - 1);
    }
};

fn eval(program: []const Expr, i: u32, vars: *const [4]u64) u64 {
    return switch (program[i]) {
        .constant => |v| v,
        .variable => |k| vars[k],
        .add => |b| (eval(program, b.lhs, vars) + eval(program, b.rhs, vars)) & MASK,
        .sub => |b| (eval(program, b.lhs, vars) + MASK + 1 - eval(program, b.rhs, vars)) & MASK,
        .mul => |b| (eval(program, b.lhs, vars) * eval(program, b.rhs, vars)) & MASK,
        .lt => |b| @intFromBool(eval(program, b.lhs, vars) < eval(program, b.rhs, vars)),
        .branch => |c| if (eval(program, c.cond, vars) != 0) eval(program, c.then, vars) else eval(program, c.other, vars),
    };
}

pub fn main(init: std.process.Init) !void {
    var g = Gen{ .state = 42, .program = .empty, .alloc = init.gpa };
    defer g.program.deinit(init.gpa);
    const root = try g.gen(MAX_DEPTH);

    var vars: [4]u64 = undefined;
    var total: u64 = 0;
    var run: u64 = 0;
    while (run < RUNS) : (run += 1) {
        for (&vars, 0..) |*v, k| {
            v.* = (run * (2 * k + 3) + k) & MASK;
        }
        total += eval(g.program.items, root, &vars);
    }

    var buf: [64]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &buf);
    const stdout = &stdout_writer.interface;
    try stdout.print("nodes = {d} checksum = {d}\n", .{ g.program.items.len, total });
    try stdout.flush();
}
