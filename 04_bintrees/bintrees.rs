const MIN_DEPTH: u32 = 4;
const MAX_DEPTH: u32 = 17;

struct Node {
    children: Option<(Box<Node>, Box<Node>)>,
}

fn bottom_up(depth: u32) -> Box<Node> {
    let children = if depth > 0 {
        Some((bottom_up(depth - 1), bottom_up(depth - 1)))
    } else {
        None
    };
    Box::new(Node { children })
}

fn check(node: &Node) -> u64 {
    match &node.children {
        Some((left, right)) => 1 + check(left) + check(right),
        None => 1,
    }
}

fn main() {
    let stretch_depth = MAX_DEPTH + 1;
    let stretch = bottom_up(stretch_depth);
    println!("stretch tree of depth {} check {}", stretch_depth, check(&stretch));
    drop(stretch);

    let long_lived = bottom_up(MAX_DEPTH);
    for depth in (MIN_DEPTH..=MAX_DEPTH).step_by(2) {
        let iterations = 1u64 << (MAX_DEPTH - depth + MIN_DEPTH);
        let total: u64 = (0..iterations).map(|_| check(&bottom_up(depth))).sum();
        println!("{} trees of depth {} check {}", iterations, depth, total);
    }
    println!("long lived tree of depth {} check {}", MAX_DEPTH, check(&long_lived));
}
