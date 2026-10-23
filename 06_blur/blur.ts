const W = 1024;
const H = 1024;
const PASSES = 100;

function blur(src: Uint32Array, dst: Uint32Array): void {
  for (let y = 0; y < H; y++) {
    const y0 = y > 0 ? y - 1 : 0;
    const y1 = y < H - 1 ? y + 1 : H - 1;
    for (let x = 0; x < W; x++) {
      const x0 = x > 0 ? x - 1 : 0;
      const x1 = x < W - 1 ? x + 1 : W - 1;
      const sum =
        src[y0 * W + x0] + src[y0 * W + x] + src[y0 * W + x1] +
        src[y * W + x0] + src[y * W + x] + src[y * W + x1] +
        src[y1 * W + x0] + src[y1 * W + x] + src[y1 * W + x1];
      dst[y * W + x] = Math.floor(sum / 9);
    }
  }
}

let a = new Uint32Array(W * H);
let b = new Uint32Array(W * H);
let state = 42;
for (let i = 0; i < W * H; i++) {
  state = (state * 48271) % 2147483647;
  a[i] = state % 256;
}
for (let pass = 0; pass < PASSES; pass++) {
  blur(a, b);
  [a, b] = [b, a];
}
let sum = 0;
for (const p of a) {
  sum += p;
}
console.log(`sum = ${sum}`);
