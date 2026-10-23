const MASK = 0xfffff;
const MAX_DEPTH = 12;
const RUNS = 40_000;

const program = [];
let state = 42;

function next() {
  state = (state * 48271) % 2147483647;
  return state;
}

function gen(depth) {
  const r = next() % 10;
  let expr;
  if (depth === 0 || r < 2) {
    expr = next() % 2 === 0 ? { kind: "const", value: next() % 100 } : { kind: "var", index: next() % 4 };
  } else if (r < 8) {
    const lhs = gen(depth - 1);
    const rhs = gen(depth - 1);
    const kind = r < 4 ? "add" : r < 5 ? "sub" : r < 7 ? "mul" : "lt";
    expr = { kind, lhs, rhs };
  } else {
    const cond = gen(depth - 1);
    const then = gen(depth - 1);
    const other = gen(depth - 1);
    expr = { kind: "if", cond, then, other };
  }
  program.push(expr);
  return program.length - 1;
}

function evaluate(i, vars) {
  const e = program[i];
  switch (e.kind) {
    case "const":
      return e.value;
    case "var":
      return vars[e.index];
    case "add":
      return (evaluate(e.lhs, vars) + evaluate(e.rhs, vars)) & MASK;
    case "sub":
      return (evaluate(e.lhs, vars) + MASK + 1 - evaluate(e.rhs, vars)) & MASK;
    case "mul":
      return (evaluate(e.lhs, vars) * evaluate(e.rhs, vars)) & MASK;
    case "lt":
      return evaluate(e.lhs, vars) < evaluate(e.rhs, vars) ? 1 : 0;
    case "if":
      return evaluate(e.cond, vars) !== 0 ? evaluate(e.then, vars) : evaluate(e.other, vars);
  }
}

const root = gen(MAX_DEPTH);
const vars = [0, 0, 0, 0];
let total = 0;
for (let run = 0; run < RUNS; run++) {
  for (let k = 0; k < 4; k++) {
    vars[k] = (run * (2 * k + 3) + k) & MASK;
  }
  total += evaluate(root, vars);
}
console.log(`nodes = ${program.length} checksum = ${total}`);
