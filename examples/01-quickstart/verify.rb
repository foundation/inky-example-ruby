# frozen_string_literal: true

# Smoke test for 01-quickstart. See SUITE.md "01 — quickstart" (in the PHP
# reference suite) for the required markers this checks.
require_relative "../../bootstrap"

dist = inky_example("01-quickstart")
path = File.join(dist, "output.html")

unless File.file?(path)
  warn "01-quickstart: missing #{path} — run examples/01-quickstart/run.rb first"
  exit 1
end

html = File.read(path)
failures = 0

unless html.include?('class="button"')
  warn '01-quickstart: expected class="button" in output (transform did not run the button component)'
  failures += 1
end

if html.include?("<button")
  warn "01-quickstart: found a bare <button> tag — transform should have replaced it with table markup"
  failures += 1
end

exit 1 if failures.positive?

puts "01-quickstart: ok"
