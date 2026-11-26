const MASK: u64 = 0xF_FFFF;
const MAX_DEPTH: u32 = 12;
const RUNS: u64 = 40_000;

enum Expr {
    Const(u64),
    Var(usize),
    Add(usize, usize),
    Sub(usize, usize),
    Mul(usize, usize),
    Lt(usize, usize),
    If(usize, usize, usize),
}

struct Gen {
    state: u64,
    program: Vec<Expr>,
}

impl Gen {
    fn next(&mut self) -> u64 {
        self.state = self.state * 48271 % 2147483647;
        self.state
    }

    fn gen(&mut self, depth: u32) -> usize {
        let r = self.next() % 10;
        let expr = if depth == 0 || r < 2 {
            if self.next() % 2 == 0 {
                Expr::Const(self.next() % 100)
            } else {
                Expr::Var((self.next() % 4) as usize)
            }
        } else if r < 8 {
            let lhs = self.gen(depth - 1);
            let rhs = self.gen(depth - 1);
            match r {
                2 | 3 => Expr::Add(lhs, rhs),
                4 => Expr::Sub(lhs, rhs),
                5 | 6 => Expr::Mul(lhs, rhs),
                _ => Expr::Lt(lhs, rhs),
            }
        } else {
            let cond = self.gen(depth - 1);
            let then = self.gen(depth - 1);
            let other = self.gen(depth - 1);
            Expr::If(cond, then, other)
        };
        self.program.push(expr);
        self.program.len() - 1
    }
}

fn eval(program: &[Expr], i: usize, vars: &[u64; 4]) -> u64 {
    match program[i] {
        Expr::Const(v) => v,
        Expr::Var(k) => vars[k],
        Expr::Add(a, b) => (eval(program, a, vars) + eval(program, b, vars)) & MASK,
        Expr::Sub(a, b) => (eval(program, a, vars) + MASK + 1 - eval(program, b, vars)) & MASK,
        Expr::Mul(a, b) => (eval(program, a, vars) * eval(program, b, vars)) & MASK,
        Expr::Lt(a, b) => (eval(program, a, vars) < eval(program, b, vars)) as u64,
        Expr::If(c, t, o) => {
            if eval(program, c, vars) != 0 {
                eval(program, t, vars)
            } else {
                eval(program, o, vars)
            }
        }
    }
}

fn main() {
    let mut g = Gen { state: 42, program: Vec::new() };
    let root = g.gen(MAX_DEPTH);
    let mut vars = [0u64; 4];
    let mut total = 0u64;
    for run in 0..RUNS {
        for (k, v) in vars.iter_mut().enumerate() {
            let k = k as u64;
            *v = (run * (2 * k + 3) + k) & MASK;
        }
        total += eval(&g.program, root, &vars);
    }
    println!("nodes = {} checksum = {}", g.program.len(), total);
}
