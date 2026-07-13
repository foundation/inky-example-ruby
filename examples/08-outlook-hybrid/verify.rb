# frozen_string_literal: true

# Smoke test for 08-outlook-hybrid. See SUITE.md "08 — outlook-hybrid" (in
# the PHP reference suite) for the required markers this checks.
require_relative "../../bootstrap"

dist = inky_example("08-outlook-hybrid")
path = File.join(dist, "launch.html")

unless File.file?(path)
  warn "08-outlook-hybrid: missing #{path} — run examples/08-outlook-hybrid/run.rb first"
  exit 1
end

html = File.read(path)
failures = 0

unless html.include?("<!--[if mso]>")
  warn "08-outlook-hybrid: expected '<!--[if mso]>' in output"
  failures += 1
end

unless html.include?("v:roundrect")
  warn "08-outlook-hybrid: expected 'v:roundrect' (bulletproof button VML) in output"
  failures += 1
end

# Every MSO conditional open ("[if mso]" or "[if !mso]") must have a
# matching "[endif]" close.
opens = html.scan("[if mso]").length + html.scan("[if !mso]").length
closes = html.scan("[endif]").length
if opens.zero?
  warn "08-outlook-hybrid: found no MSO conditional opens at all"
  failures += 1
elsif opens != closes
  warn "08-outlook-hybrid: unbalanced MSO conditionals — #{opens} opens vs #{closes} closes"
  failures += 1
end

exit 1 if failures.positive?

puts "08-outlook-hybrid: ok"
