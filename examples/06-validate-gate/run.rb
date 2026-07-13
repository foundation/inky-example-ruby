# frozen_string_literal: true

# 06 — validate-gate
#
# A CI-style pre-send gate: run Inky.validate over a template and block a
# send if it has any *error*-severity diagnostic (warnings are reported
# but don't block). validate_or_fail() below is the reusable gate — copy
# it straight into a CI step or a pre-send hook.
#
# RUNNER SEAM — read this before changing how this file is invoked:
#   - `ruby run.rb <path> [<path> ...]` is the REAL gate. It calls
#     validate_or_fail() on the given paths, which exits the process with
#     1 if any of them has an error, or lets it fall through to exit 0
#     otherwise. verify.rb always invokes this file with explicit argv
#     paths so it observes true exit codes (bad.inky alone -> exit 1,
#     good.inky alone -> exit 0).
#   - `ruby run.rb` with NO args is the suite-runner path (this is what
#     `ruby run_all.rb` calls for every example). This example's whole
#     point is to demonstrate a FAILING gate, but run_all.rb runs every
#     example unconditionally, so the no-args branch demonstrates BOTH
#     good.inky (passes) and bad.inky (fails) by hand — printing
#     diagnostics and the exit code the gate WOULD have produced for each
#     — without ever calling exit(1) itself. It always exits 0. (run_all.rb
#     also carries a matching exemption comment for this example,
#     belt-and-suspenders.)

require_relative "../../bootstrap"

dist = inky_example("06-validate-gate")

# Validate one template and print its diagnostics grouped by severity.
# Returns true iff it has at least one error-severity diagnostic.
def report_diagnostics(path)
  html = File.read(path)
  diagnostics = Inky.validate(html)

  errors = diagnostics.select { |d| d[:severity] == "error" }
  warnings = diagnostics.select { |d| d[:severity] == "warning" }

  puts "#{File.basename(path)}:"
  errors.each { |d| puts "  ERROR   [#{d[:rule]}] #{d[:message]}" }
  warnings.each { |d| puts "  WARNING [#{d[:rule]}] #{d[:message]}" }
  puts "  (clean)" if diagnostics.empty?

  !errors.empty?
end

# The reusable pre-send gate. Validate every path, print diagnostics for
# each, and exit(1) as soon as it's known at least one has an error.
def validate_or_fail(paths)
  has_errors = false
  paths.each do |path|
    has_errors = true if report_diagnostics(path)
  end
  exit 1 if has_errors
end

arg_paths = ARGV

if !arg_paths.empty?
  # Real invocation: exactly what a CI step or pre-send hook would run.
  validate_or_fail(arg_paths)
  puts "gate: passed"
  File.write(File.join(dist, "report.txt"), "gate: passed for #{arg_paths.map { |p| File.basename(p) }.join(', ')}\n")
  exit 0
end

# No-args demo path — see the header comment above.
good = File.join(__dir__, "good.inky")
bad = File.join(__dir__, "bad.inky")

good_failed = report_diagnostics(good)
puts "  -> gate would exit #{good_failed ? '1 (blocked)' : '0 (passed)'}\n\n"

bad_failed = report_diagnostics(bad)
puts "  -> gate would exit #{bad_failed ? '1 (blocked)' : '0 (passed)'}"

File.write(
  File.join(dist, "report.txt"),
  "good.inky would exit #{good_failed ? 1 : 0}\n" \
  "bad.inky would exit #{bad_failed ? 1 : 0}\n"
)
