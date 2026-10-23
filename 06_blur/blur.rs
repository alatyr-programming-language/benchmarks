const W: usize = 1024;
const H: usize = 1024;
const PASSES: u32 = 100;

fn blur(src: &[u32], dst: &mut [u32]) {
    for y in 0..H {
        let y0 = y.saturating_sub(1);
        let y1 = (y + 1).min(H - 1);
        for x in 0..W {
            let x0 = x.saturating_sub(1);
            let x1 = (x + 1).min(W - 1);
            let sum = src[y0 * W + x0] + src[y0 * W + x] + src[y0 * W + x1]
                + src[y * W + x0] + src[y * W + x] + src[y * W + x1]
                + src[y1 * W + x0] + src[y1 * W + x] + src[y1 * W + x1];
            dst[y * W + x] = sum / 9;
        }
    }
}

fn main() {
    let mut state: u64 = 42;
    let mut a: Vec<u32> = (0..W * H)
        .map(|_| {
            state = state * 48271 % 2147483647;
            (state % 256) as u32
        })
        .collect();
    let mut b = vec![0u32; W * H];
    for _ in 0..PASSES {
        blur(&a, &mut b);
        std::mem::swap(&mut a, &mut b);
    }
    let sum: u64 = a.iter().map(|&p| u64::from(p)).sum();
    println!("sum = {sum}");
}
