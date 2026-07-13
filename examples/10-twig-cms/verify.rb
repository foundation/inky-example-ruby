# frozen_string_literal: true

# Smoke test for 10-twig-cms. See SUITE.md "10 — twig-cms" (in the PHP
# reference suite) for the required markers this checks.
require_relative "../../bootstrap"
require "open3"

dir = __dir__
dist = inky_example("10-twig-cms")
failures = 0

output, status = Open3.capture2e("ruby", File.join(dir, "run.rb"))

if status.exitstatus != 0
  warn "10-twig-cms: run.rb exited #{status.exitstatus}\n#{output}"
  failures += 1
end

# All six outputs exist.
%w[a b].each do |order|
  (1..3).each do |n|
    path = File.join(dist, "order-#{order}-#{n}.html")
    unless File.file?(path)
      warn "10-twig-cms: missing #{path}"
      failures += 1
    end
  end
end

# Recipient 1: the correctness claim. Compared with insignificant inter-tag
# whitespace normalized (">\s+<" -> "><") — the same whitespace inky-core's
# own break_long_lines comment calls out as not affecting rendering. See
# run.rb's own comment above this same check for the full explanation of
# why a raw byte comparison doesn't hold and what the normalization does
# (and does not) paper over.
a1 = File.exist?(File.join(dist, "order-a-1.html")) ? File.read(File.join(dist, "order-a-1.html")) : ""
b1 = File.exist?(File.join(dist, "order-b-1.html")) ? File.read(File.join(dist, "order-b-1.html")) : ""
normalize = ->(html) { html.gsub(/>\s+</, "><") }
if a1.empty? || b1.empty? || normalize.call(a1) != normalize.call(b1)
  warn "10-twig-cms: order-a-1.html and order-b-1.html are not equal (ignoring inter-tag whitespace)"
  failures += 1
end

# Timing lines printed.
unless /orderA:\s*[\d.]+\s*ms,\s*orderB:\s*[\d.]+\s*ms \(shell built once\)/.match(output)
  warn "10-twig-cms: expected an 'orderA: X ms, orderB: Y ms (shell built once)' line, got:\n#{output}"
  failures += 1
end

# No un-rendered Liquid syntax in any final output.
Dir.glob(File.join(dist, "order-*.html")).each do |path|
  html = File.read(path)
  if html.include?("{{")
    warn "10-twig-cms: found un-rendered '{{' in #{File.basename(path)}"
    failures += 1
  end
end

exit 1 if failures.positive?

puts "10-twig-cms: ok"
