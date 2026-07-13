# frozen_string_literal: true

# Smoke test for 07-migrate. See SUITE.md "07 — migrate" (in the PHP
# reference suite) for the required markers this checks.
require_relative "../../bootstrap"

dist = inky_example("07-migrate")
migrated_path = File.join(dist, "migrated.inky")
built_path = File.join(dist, "email.html")

unless File.file?(migrated_path) && File.file?(built_path)
  warn "07-migrate: missing dist output — run examples/07-migrate/run.rb first"
  exit 1
end

migrated = File.read(migrated_path)
built = File.read(built_path)
failures = 0

unless migrated.include?('lg="')
  warn '07-migrate: expected lg=" in migrated output (large -> lg did not happen)'
  failures += 1
end

if migrated.include?('large="')
  warn '07-migrate: found leftover large=" in migrated output'
  failures += 1
end

# Re-run migrate_with_details directly to check the reported change count
# (run.rb only writes files; re-deriving here keeps this check honest
# without parsing run.rb's stdout).
legacy = File.read(File.join(__dir__, "legacy-v1.inky"))
result = Inky.migrate_with_details(legacy)
change_count = result[:changes].length
if change_count < 5
  warn "07-migrate: expected at least 5 changes, got #{change_count}"
  failures += 1
end

unless built.include?("<table")
  warn "07-migrate: expected <table in built output (migrated template did not build to table markup)"
  failures += 1
end

exit 1 if failures.positive?

puts "07-migrate: ok"
