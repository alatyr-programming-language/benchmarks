const N: u64 = 10_000_000;

fn main() {
    let mut a: Vec<u64> = Vec::with_capacity(N as usize);
    for i in 0..N {
        a.push(i);
    }
    let sum: u64 = a.iter().sum();
    println!("sum = {sum}");
}
