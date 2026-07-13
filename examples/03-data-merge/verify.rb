# frozen_string_literal: true

# Smoke test for 03-data-merge. See SUITE.md "03 — data-merge" (in the PHP
# reference suite) for the required markers this checks.
require_relative "../../bootstrap"

dist = inky_example("03-data-merge")
path = File.join(dist, "order.html")

unless File.file?(path)
  warn "03-data-merge: missing #{path} — run examples/03-data-merge/run.rb first"
  exit 1
end

html = File.read(path)
failures = 0

unless html.include?("NW-10482")
  warn "03-data-merge: expected the order number NW-10482 (customer/order variables did not merge)"
  failures += 1
end

row_count = html.scan('<tr class="line-item"').length
if row_count != 3
  warn "03-data-merge: expected exactly 3 line-item rows, found #{row_count}"
  failures += 1
end

if html.include?("{%")
  warn "03-data-merge: found un-merged '{%' template syntax in output"
  failures += 1
end

exit 1 if failures.positive?

puts "03-data-merge: ok"
