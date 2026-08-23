LIMIT = 1_000_000

def is_prime(n)
  return false if n < 2
  j = 2
  while j * j <= n
    return false if n % j == 0
    j += 1
  end
  true
end

count = 0
i = 2
while i < LIMIT
  count += 1 if is_prime(i)
  i += 1
end
puts "primes = #{count}"
