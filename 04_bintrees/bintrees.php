<?php

const MIN_DEPTH = 4;
const MAX_DEPTH = 17;

final class Node {
    public function __construct(
        public readonly ?Node $left = null,
        public readonly ?Node $right = null,
    ) {}

    public function check(): int {
        if ($this->left === null) {
            return 1;
        }
        return 1 + $this->left->check() + $this->right->check();
    }
}

function bottom_up(int $depth): Node {
    if ($depth === 0) {
        return new Node();
    }
    return new Node(bottom_up($depth - 1), bottom_up($depth - 1));
}

$stretchDepth = MAX_DEPTH + 1;
echo "stretch tree of depth $stretchDepth check " . bottom_up($stretchDepth)->check() . "\n";

$longLived = bottom_up(MAX_DEPTH);
for ($depth = MIN_DEPTH; $depth <= MAX_DEPTH; $depth += 2) {
    $iterations = 1 << (MAX_DEPTH - $depth + MIN_DEPTH);
    $total = 0;
    for ($i = 0; $i < $iterations; $i++) {
        $total += bottom_up($depth)->check();
    }
    echo "$iterations trees of depth $depth check $total\n";
}
echo "long lived tree of depth " . MAX_DEPTH . " check " . $longLived->check() . "\n";
