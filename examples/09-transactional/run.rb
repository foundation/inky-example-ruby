# frozen_string_literal: true

# 09 — transactional (capstone)
#
# A realistic three-email transactional set for Northwind Coffee — welcome,
# receipt, password reset — built with EmailRenderer (src/email_renderer.rb)
# instead of raw Inky.build calls. This is the shape a real app uses: one
# shared theme, one template directory, JSON data per email, and a
# build-shell cache so re-rendering the same email (e.g. a retried send)
# skips redoing the work.
#
# Run this file twice in a row to see the cache take effect on the second
# pass — `ruby run_all.rb` / `ruby run_all.rb --verify` already does, via
# run.rb and verify.rb respectively.

require_relative "../../bootstrap"
require_relative "../../src/email_renderer"

dist = inky_example("09-transactional")
cache_dir = File.join(__dir__, "cache")

# This emails/ dir is the convention: what you'd point Total CMS (or any
# real CMS) at — one self-contained base_path, everything under it
# root-relative (layouts/, themes/, includes/ — see emails/layouts/main.html
# for the resolution rule), no traversal outside the tree at all. It's the
# same base_path EmailRenderer's template_dir doubles as for Inky.build;
# template filenames passed to #render below are therefore bare
# "....inky" names, relative to emails/ itself, not a "templates/" prefix.
renderer = EmailRenderer.new(
  File.join(__dir__, "emails"),
  File.join(__dir__, "emails", "themes", "northwind.scss"),
  cache_dir: cache_dir,
)

emails = [
  { name: "welcome", template: "welcome.inky", data: "data/welcome.json" },
  { name: "receipt", template: "receipt.inky", data: "data/receipt.json" },
  { name: "password-reset", template: "password-reset.inky", data: "data/password-reset.json" },
]

summary = []
total_warnings = 0

emails.each do |email|
  data = JSON.parse(File.read(File.join(__dir__, email[:data])))

  # EmailRenderer doesn't report cache hit/miss directly, so detect it
  # from the outside: a cache HIT reads an existing file and writes
  # nothing new, so the cache directory's file count won't change.
  before = Dir.glob(File.join(cache_dir, "*.json")).length
  result = renderer.render(email[:template], data: data)
  after = Dir.glob(File.join(cache_dir, "*.json")).length
  cache_status = after > before ? "miss (built + cached)" : "hit (served from cache)"

  File.write(File.join(dist, "#{email[:name]}.html"), result.html)
  File.write(File.join(dist, "#{email[:name]}.txt"), result.text)

  warning_count = result.warnings.length
  total_warnings += warning_count

  summary << [email[:name], result.html.bytesize + result.text.bytesize, warning_count, cache_status]
end

puts "Email".ljust(18) + "Bytes".ljust(10) + "Warnings".ljust(10) + "Cache"
summary.each do |name, bytes, warnings, cache_status|
  puts name.ljust(18) + bytes.to_s.ljust(10) + warnings.to_s.ljust(10) + cache_status
end

puts
puts "total warnings: #{total_warnings}"
