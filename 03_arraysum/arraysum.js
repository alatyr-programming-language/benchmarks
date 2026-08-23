const N = 10_000_000;

const a = new Array(N);
for (let i = 0; i < N; i++) {
  a[i] = i;
}
let sum = 0;
for (let i = 0; i < N; i++) {
  sum += a[i];
}
console.log("sum = " + sum);
