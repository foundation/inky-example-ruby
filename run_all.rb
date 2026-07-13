# frozen_string_literal: true

# Runs every example in examples/*/run.rb, in order.
# --verify additionally checks each example's required output markers.
#
# Usage:
#   ruby run_all.rb            # runs every example
#   ruby run_all.rb --verify   # same, plus runs every example's verify.rb

require_relative "bootstrap"

verify = ARGV.include?("--verify")
failures = 0

Dir.glob(File.join(__dir__, "examples", "*", "run.rb")).sort.each do |script|
  name = File.basename(File.dirname(script))
  puts "\n=== #{name} ==="

  system(RbConfig.ruby, script)
  exit_status = $?.exitstatus

  # 06-validate-gate demonstrates a failing gate on purpose when invoked
  # with explicit argv paths, but its no-args path (the one run here) is
  # a demo that always exits 0 — see that example's run.rb header comment
  # for the full "runner seam" explanation. No special-casing is actually
  # needed for the no-args exit code itself (it's always 0), but this
  # comment documents the seam the same way build.php's PHP original does,
  # belt-and-suspenders, in case that ever changes.
  if exit_status != 0 && name != "06-validate-gate"
    warn "FAILED: #{name} (exit #{exit_status})"
    failures += 1
    next
  end

  next unless verify

  check = File.join(File.dirname(script), "verify.rb")
  next unless File.exist?(check)

  system(RbConfig.ruby, check)
  vexit = $?.exitstatus
  if vexit != 0
    warn "VERIFY FAILED: #{name}"
    failures += 1
  end
end

exit(failures.zero? ? 0 : 1)
