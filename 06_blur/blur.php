<?php

const W = 1024;
const H = 1024;
const PASSES = 100;

function blur(array $src, array &$dst): void {
    for ($y = 0; $y < H; $y++) {
        $r0 = max($y - 1, 0) * W;
        $r1 = $y * W;
        $r2 = min($y + 1, H - 1) * W;
        for ($x = 0; $x < W; $x++) {
            $x0 = max($x - 1, 0);
            $x1 = min($x + 1, W - 1);
            $sum = $src[$r0 + $x0] + $src[$r0 + $x] + $src[$r0 + $x1]
                + $src[$r1 + $x0] + $src[$r1 + $x] + $src[$r1 + $x1]
                + $src[$r2 + $x0] + $src[$r2 + $x] + $src[$r2 + $x1];
            $dst[$r1 + $x] = intdiv($sum, 9);
        }
    }
}

$a = [];
$state = 42;
for ($i = 0; $i < W * H; $i++) {
    $state = $state * 48271 % 2147483647;
    $a[] = $state % 256;
}
$b = array_fill(0, W * H, 0);
for ($pass = 0; $pass < PASSES; $pass++) {
    blur($a, $b);
    [$a, $b] = [$b, $a];
}
echo "sum = " . array_sum($a) . "\n";
