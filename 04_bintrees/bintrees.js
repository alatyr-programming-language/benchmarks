const MIN_DEPTH = 4;
const MAX_DEPTH = 17;

class Node {
  constructor(left, right) {
    this.left = left;
    this.right = right;
  }

  check() {
    if (this.left === null) {
      return 1;
    }
    return 1 + this.left.check() + this.right.check();
  }
}

function bottomUp(depth) {
  if (depth === 0) {
    return new Node(null, null);
  }
  return new Node(bottomUp(depth - 1), bottomUp(depth - 1));
}

const stretchDepth = MAX_DEPTH + 1;
console.log(`stretch tree of depth ${stretchDepth} check ${bottomUp(stretchDepth).check()}`);

const longLived = bottomUp(MAX_DEPTH);
for (let depth = MIN_DEPTH; depth <= MAX_DEPTH; depth += 2) {
  const iterations = 1 << (MAX_DEPTH - depth + MIN_DEPTH);
  let total = 0;
  for (let i = 0; i < iterations; i++) {
    total += bottomUp(depth).check();
  }
  console.log(`${iterations} trees of depth ${depth} check ${total}`);
}
console.log(`long lived tree of depth ${MAX_DEPTH} check ${longLived.check()}`);
