# frozen_string_literal: true

# Smoke test for 04-theming. See SUITE.md "04 — theming" (in the PHP
# reference suite) for the required markers this checks.
require_relative "../../bootstrap"

dist = inky_example("04-theming")
northwind_path = File.join(dist, "promo-northwind.html")
midnight_path = File.join(dist, "promo-midnight.html")

unless File.file?(northwind_path) && File.file?(midnight_path)
  warn "04-theming: missing promo-northwind.html and/or promo-midnight.html — run examples/04-theming/run.rb first"
  exit 1
end

northwind = File.read(northwind_path)
midnight = File.read(midnight_path)
failures = 0

unless northwind.include?("#6f4e37")
  warn "04-theming: expected the northwind theme color #6f4e37 in promo-northwind.html"
  failures += 1
end

unless midnight.include?("#4a6cf7")
  warn "04-theming: expected the midnight theme color #4a6cf7 in promo-midnight.html"
  failures += 1
end

if northwind == midnight
  warn "04-theming: promo-northwind.html and promo-midnight.html are byte-identical — the theme swap did not take effect"
  failures += 1
end

exit 1 if failures.positive?

puts "04-theming: ok"
