<?php

ini_set('memory_limit', '-1');

const N = 10000000;

$a = [];
for ($i = 0; $i < N; $i++) {
    $a[$i] = $i;
}
$sum = 0;
for ($i = 0; $i < N; $i++) {
    $sum += $a[$i];
}
echo "sum = $sum\n";
