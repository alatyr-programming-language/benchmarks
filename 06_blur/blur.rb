W = 1024
H = 1024
PASSES = 100

def blur(src, dst)
  H.times do |y|
    r0 = [y - 1, 0].max * W
    r1 = y * W
    r2 = [y + 1, H - 1].min * W
    W.times do |x|
      x0 = x > 0 ? x - 1 : 0
      x1 = x < W - 1 ? x + 1 : W - 1
      sum = src[r0 + x0] + src[r0 + x] + src[r0 + x1] +
            src[r1 + x0] + src[r1 + x] + src[r1 + x1] +
            src[r2 + x0] + src[r2 + x] + src[r2 + x1]
      dst[r1 + x] = sum / 9
    end
  end
end

state = 42
a = Array.new(W * H) do
  state = state * 48271 % 2147483647
  state % 256
end
b = Array.new(W * H, 0)
PASSES.times do
  blur(a, b)
  a, b = b, a
end
puts "sum = #{a.sum}"
