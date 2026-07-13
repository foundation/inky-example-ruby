# frozen_string_literal: true

# Smoke test for 02-build-pipeline. See SUITE.md "02 — build-pipeline" (in
# the PHP reference suite) for the required markers this checks.
require_relative "../../bootstrap"

dist = inky_example("02-build-pipeline")
path = File.join(dist, "email.html")

unless File.file?(path)
  warn "02-build-pipeline: missing #{path} — run examples/02-build-pipeline/run.rb first"
  exit 1
end

html = File.read(path)
failures = 0

unless html.include?("<html")
  warn "02-build-pipeline: expected <html — the shared layout was not applied"
  failures += 1
end

unless html.include?("Northwind Coffee")
  warn '02-build-pipeline: expected the shared header include\'s wordmark text ("Northwind Coffee")'
  failures += 1
end

unless html.include?("#6f4e37")
  warn "02-build-pipeline: expected the compiled northwind theme color #6f4e37 (linked SCSS was not compiled in)"
  failures += 1
end

exit 1 if failures.positive?

puts "02-build-pipeline: ok"
