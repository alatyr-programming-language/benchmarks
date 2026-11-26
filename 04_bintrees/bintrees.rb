MIN_DEPTH = 4
MAX_DEPTH = 17

Node = Struct.new(:left, :right) do
  def check
    return 1 if left.nil?
    1 + left.check + right.check
  end
end

def bottom_up(depth)
  return Node.new(nil, nil) if depth.zero?
  Node.new(bottom_up(depth - 1), bottom_up(depth - 1))
end

stretch_depth = MAX_DEPTH + 1
puts "stretch tree of depth #{stretch_depth} check #{bottom_up(stretch_depth).check}"

long_lived = bottom_up(MAX_DEPTH)
MIN_DEPTH.step(MAX_DEPTH, 2) do |depth|
  iterations = 1 << (MAX_DEPTH - depth + MIN_DEPTH)
  total = 0
  iterations.times { total += bottom_up(depth).check }
  puts "#{iterations} trees of depth #{depth} check #{total}"
end
puts "long lived tree of depth #{MAX_DEPTH} check #{long_lived.check}"
