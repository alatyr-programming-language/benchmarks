MASK = 0xFFFFF
MAX_DEPTH = 12
RUNS = 40_000

class Gen
  attr_reader :program

  def initialize(seed)
    @state = seed
    @program = []
  end

  def next_value
    @state = @state * 48271 % 2147483647
  end

  def gen(depth)
    r = next_value % 10
    expr =
      if depth.zero? || r < 2
        next_value.even? ? [:const, next_value % 100] : [:var, next_value % 4]
      elsif r < 8
        lhs = gen(depth - 1)
        rhs = gen(depth - 1)
        op = if r < 4 then :add elsif r < 5 then :sub elsif r < 7 then :mul else :lt end
        [op, lhs, rhs]
      else
        cond = gen(depth - 1)
        yes = gen(depth - 1)
        no = gen(depth - 1)
        [:if, cond, yes, no]
      end
    @program << expr
    @program.size - 1
  end
end

def evaluate(program, i, vars)
  op, a, b, c = program[i]
  case op
  when :const then a
  when :var then vars[a]
  when :add then (evaluate(program, a, vars) + evaluate(program, b, vars)) & MASK
  when :sub then (evaluate(program, a, vars) + MASK + 1 - evaluate(program, b, vars)) & MASK
  when :mul then (evaluate(program, a, vars) * evaluate(program, b, vars)) & MASK
  when :lt then evaluate(program, a, vars) < evaluate(program, b, vars) ? 1 : 0
  when :if then evaluate(program, a, vars) != 0 ? evaluate(program, b, vars) : evaluate(program, c, vars)
  end
end

g = Gen.new(42)
root = g.gen(MAX_DEPTH)
program = g.program
total = 0
RUNS.times do |run|
  vars = Array.new(4) { |k| (run * (2 * k + 3) + k) & MASK }
  total += evaluate(program, root, vars)
end
puts "nodes = #{program.size} checksum = #{total}"
