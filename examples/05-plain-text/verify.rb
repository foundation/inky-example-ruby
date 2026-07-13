# frozen_string_literal: true

# Smoke test for 05-plain-text. See SUITE.md "05 — plain-text" (in the PHP
# reference suite) for the required markers this checks.
require_relative "../../bootstrap"

dist = inky_example("05-plain-text")
html_path = File.join(dist, "digest.html")
txt_path = File.join(dist, "digest.txt")

unless File.file?(html_path) && File.file?(txt_path)
  warn "05-plain-text: missing digest.html and/or digest.txt — run examples/05-plain-text/run.rb first"
  exit 1
end

html = File.read(html_path)
text = File.read(txt_path)
failures = 0

# The plain-text renderer uppercases headings, so compare case-insensitively.
headline = "This week at Northwind Coffee"
unless html.include?(headline)
  warn "05-plain-text: expected the digest headline \"#{headline}\" in digest.html"
  failures += 1
end
unless text.downcase.include?(headline.downcase)
  warn "05-plain-text: expected the digest headline \"#{headline}\" in digest.txt"
  failures += 1
end

if text.include?("<")
  warn "05-plain-text: found a '<' character in digest.txt — plain text should have no markup"
  failures += 1
end

exit 1 if failures.positive?

puts "05-plain-text: ok"
