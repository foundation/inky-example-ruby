# frozen_string_literal: true

# Smoke test for 06-validate-gate. See SUITE.md "06 — validate-gate" (in
# the PHP reference suite) for the required markers this checks. Runs
# run.rb as a subprocess with explicit argv paths so it observes the REAL
# gate exit codes — the no-args path is a demo only and always exits 0
# (see run.rb's header).
require_relative "../../bootstrap"
require "open3"

dir = __dir__
failures = 0

def run_gate(dir, *paths)
  cmd = ["ruby", File.join(dir, "run.rb"), *paths]
  output, status = Open3.capture2e(*cmd)
  [status.exitstatus, output]
end

# bad.inky alone -> exit 1, with distinct rule ids present in the output.
bad_exit, bad_output = run_gate(dir, File.join(dir, "bad.inky"))

if bad_exit != 1
  warn "06-validate-gate: expected exit 1 for bad.inky, got #{bad_exit}\n#{bad_output}"
  failures += 1
end
unless bad_output.include?("button-no-href")
  warn "06-validate-gate: expected rule id 'button-no-href' in output"
  failures += 1
end
unless bad_output.include?("missing-preheader")
  warn "06-validate-gate: expected rule id 'missing-preheader' in output"
  failures += 1
end

# good.inky alone -> exit 0.
good_exit, good_output = run_gate(dir, File.join(dir, "good.inky"))

if good_exit != 0
  warn "06-validate-gate: expected exit 0 for good.inky, got #{good_exit}\n#{good_output}"
  failures += 1
end

exit 1 if failures.positive?

puts "06-validate-gate: ok"
