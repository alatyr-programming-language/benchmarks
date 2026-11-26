<?php

const MASK = 0xFFFFF;
const MAX_DEPTH = 12;
const RUNS = 40000;

enum Op {
    case Const;
    case Var;
    case Add;
    case Sub;
    case Mul;
    case Lt;
    case If;
}

final class Gen {
    public array $program = [];

    public function __construct(private int $state) {}

    private function next(): int {
        $this->state = $this->state * 48271 % 2147483647;
        return $this->state;
    }

    public function gen(int $depth): int {
        $r = $this->next() % 10;
        if ($depth === 0 || $r < 2) {
            $expr = $this->next() % 2 === 0
                ? [Op::Const, $this->next() % 100]
                : [Op::Var, $this->next() % 4];
        } elseif ($r < 8) {
            $lhs = $this->gen($depth - 1);
            $rhs = $this->gen($depth - 1);
            $op = match (true) {
                $r < 4 => Op::Add,
                $r < 5 => Op::Sub,
                $r < 7 => Op::Mul,
                default => Op::Lt,
            };
            $expr = [$op, $lhs, $rhs];
        } else {
            $cond = $this->gen($depth - 1);
            $then = $this->gen($depth - 1);
            $other = $this->gen($depth - 1);
            $expr = [Op::If, $cond, $then, $other];
        }
        $this->program[] = $expr;
        return count($this->program) - 1;
    }
}

function evaluate(array $program, int $i, array $vars): int {
    $e = $program[$i];
    return match ($e[0]) {
        Op::Const => $e[1],
        Op::Var => $vars[$e[1]],
        Op::Add => (evaluate($program, $e[1], $vars) + evaluate($program, $e[2], $vars)) & MASK,
        Op::Sub => (evaluate($program, $e[1], $vars) + MASK + 1 - evaluate($program, $e[2], $vars)) & MASK,
        Op::Mul => (evaluate($program, $e[1], $vars) * evaluate($program, $e[2], $vars)) & MASK,
        Op::Lt => evaluate($program, $e[1], $vars) < evaluate($program, $e[2], $vars) ? 1 : 0,
        Op::If => evaluate($program, $e[1], $vars) !== 0
            ? evaluate($program, $e[2], $vars)
            : evaluate($program, $e[3], $vars),
    };
}

$g = new Gen(42);
$root = $g->gen(MAX_DEPTH);
$program = $g->program;
$total = 0;
for ($run = 0; $run < RUNS; $run++) {
    $vars = [];
    for ($k = 0; $k < 4; $k++) {
        $vars[] = ($run * (2 * $k + 3) + $k) & MASK;
    }
    $total += evaluate($program, $root, $vars);
}
echo "nodes = " . count($program) . " checksum = $total\n";
