# frozen_string_literal: true

# Smoke test for 09-transactional. See SUITE.md "09 — transactional
# (capstone)" (in the PHP reference suite) for the required markers this
# checks. Runs run.rb TWICE as a subprocess (mirroring the
# 06-validate-gate pattern) so the second invocation observes a warm
# EmailRenderer cache, even on a clean checkout where the first-ever
# invocation (here or from run_all.rb) was a miss.
require_relative "../../bootstrap"
require "open3"

dir = __dir__
dist = inky_example("09-transactional")
failures = 0

# EmailRenderer#render's cache-hit path returns an Inky::BuildResult with
# an empty warnings array unconditionally (see src/email_renderer.rb) — it
# never re-runs Inky.build on a hit, so it has no warnings to report, not
# because the template is actually warning-clean. Asserting "zero
# warnings" against a run that's all cache hits would therefore pass even
# if the templates were full of warnings, as long as a prior run had ever
# cached them. So: clear the cache first, run once COLD and assert zero
# warnings from THAT run (the only run that actually asks Inky.build to
# check), then run again and confirm the second run is all cache hits.
cache_dir = File.join(dir, "cache")
Dir.glob(File.join(cache_dir, "*.json")).each { |f| File.delete(f) }

def run_capstone(dir)
  output, status = Open3.capture2e("ruby", File.join(dir, "run.rb"))
  [status.exitstatus, output]
end

first_exit, first_output = run_capstone(dir)
second_exit, second_output = run_capstone(dir)

if first_exit != 0 || second_exit != 0
  warn "09-transactional: run.rb exited non-zero (first=#{first_exit}, second=#{second_exit})\n#{second_output}"
  failures += 1
end

hit_count = second_output.scan("hit (served from cache)").length
if hit_count != 3
  warn "09-transactional: expected 3 cache hits on the second run.rb invocation, found #{hit_count}\n#{second_output}"
  failures += 1
end

# Checked against the FIRST (cold) run's output, not the second (warm) run
# — a warm run always reports zero warnings regardless of template health
# (see the comment above), so it can't tell us anything about whether the
# templates are actually warning-clean.
if (m = /total warnings:\s*(\d+)/.match(first_output))
  if m[1].to_i != 0
    warn "09-transactional: expected zero warnings across all three templates on the cold run, output:\n#{first_output}"
    failures += 1
  end
else
  warn "09-transactional: could not find 'total warnings:' line in cold run output:\n#{first_output}"
  failures += 1
end

# Six output files: three emails, each .html + .txt.
%w[welcome receipt password-reset].each do |name|
  %w[html txt].each do |ext|
    path = File.join(dist, "#{name}.#{ext}")
    unless File.file?(path)
      warn "09-transactional: missing #{path}"
      failures += 1
    end
  end
end

# Receipt totals row: a "$"-amount inside the totals row specifically.
receipt_html = File.exist?(File.join(dist, "receipt.html")) ? File.read(File.join(dist, "receipt.html")) : ""
totals_match = /<tr class="totals-row"[^>]*>.*?<\/tr>/m.match(receipt_html)
unless totals_match && /\$[0-9]/.match(totals_match[0])
  warn '09-transactional: expected a $-amount inside <tr class="totals-row">...</tr> in receipt.html'
  failures += 1
end

exit 1 if failures.positive?

puts "09-transactional: ok"
