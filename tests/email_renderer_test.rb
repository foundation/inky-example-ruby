# frozen_string_literal: true

##
# Plain-Ruby smoke test for src/EmailRenderer.rb — no test framework, just
# assertions and an exit code. Run directly: `ruby tests/email_renderer_test.rb`
#
# Exit 0 = all assertions passed. Exit 1 = at least one failed (message on STDERR).

require_relative "../bootstrap"
require_relative "../src/email_renderer"
require "fileutils"
require "tempfile"
require "time"

failures = 0

def check(label, condition)
  if condition
    puts "  ok - #{label}"
  else
    puts "  FAIL - #{label}"
    yield if block_given?
  end
  condition ? 0 : 1
end

# template_dir (== base_path passed to Inky.build) must sit exactly two
# directories below the repo root, the same depth as examples/NN-name/,
# because shared/layout.html's own includes (e.g.
# "../../shared/includes/header.html") — and sample.inky's own
# `<layout src="../../shared/layout.html">` — resolve against that
# original base_path, not against the file's own directory (see SUITE.md
# "Runtime requirements"). tests/fixtures/ is that depth (tests, fixtures);
# the actual template files live one level deeper, in fixtures/templates/,
# so every render() call below passes a "templates/..." relative filename.
this_dir = File.dirname(File.expand_path(__FILE__))
template_dir = File.join(this_dir, "fixtures")
theme_path = File.join(this_dir, "fixtures", "theme.scss")
cache_dir = File.join(Dir.tmpdir, "inky-example-ruby-test-cache-#{Process.pid}")

# Clean slate for the cache directory used below.
FileUtils.rm_rf(cache_dir) if Dir.exist?(cache_dir)

# --- 1. Basic render: layout-based template (the real architecture) -------
# This is the regression pin: sample.inky starts with `<layout src="...">`,
# exactly like every real template in this suite (see shared/layout.html
# and examples 09/10). It has NO literal `</head>` of its own — that tag
# only exists inside the layout file, which the child never sees directly.
# The old EmailRenderer#render injected the theme <link> via a raw
# str.sub("</head>", ...) against the CHILD template source, before
# the layout was resolved — so on a layout-based template it silently
# matched nothing, and the theme was never compiled in. This assertion
# (the compiled color from the theme, #123abc) fails on that old code.
puts "1. basic render, layout-based template (data merge, theme color, plain text)"
renderer = EmailRenderer.new(template_dir, theme_path)
result = renderer.render("templates/sample.inky", data: { "name" => "Ada" }, options: { inline_css: true, framework_css: true })

failures += check("html contains the layout document (<html)", result.html.include?("<html"))
failures += check("html contains merged data value", result.html.include?("Ada"))
failures += check("html contains compiled theme color (#123abc)", result.html.include?("123abc"))
failures += check("no literal <link> tag survives (extractor stripped it)", !result.html.include?("<link"))
failures += check("text is non-null", !result.text.nil?)
failures += check("no warnings for a clean template", result.warnings == [])

# --- 1b. Basic render: full-document template (no <layout>, has <head>) ---
# Keeps the OTHER inject_theme_link() branch covered: a template that is
# already a complete document with a literal </head> should still get the
# theme link spliced in before it (the pre-existing, still-correct path).
puts "1b. basic render, no-layout template (theme color still present)"
no_layout_result = renderer.render("templates/no-layout.inky", data: { "name" => "Ada" }, options: { inline_css: true, framework_css: true })

failures += check("no-layout html contains merged data value", no_layout_result.html.include?("Ada"))
failures += check("no-layout html contains compiled theme color (#123abc)", no_layout_result.html.include?("123abc"))
failures += check("no-layout html has no literal <link> tag surviving", !no_layout_result.html.include?("<link"))

# --- 2. Cache path: second render hits the cache ---------------------------
puts "2. cache path (second render with cache_dir hits cache)"
caching_renderer = EmailRenderer.new(template_dir, theme_path, cache_dir: cache_dir)
first = caching_renderer.render("templates/sample.inky", data: { "name" => "Ada" }, options: { inline_css: true, framework_css: true })

cache_files = Dir.glob(File.join(cache_dir, "*.json"))
failures += check("exactly one cache file written after first render", cache_files.length == 1)

cache_file = cache_files[0]
mtime_before = nil
if cache_file
  # Back-date the cache file so a rewrite (i.e. a cache miss) would be detectable.
  back_dated = Time.now - 100
  File.utime(back_dated, back_dated, cache_file)
  mtime_before = File.mtime(cache_file)
end

second = caching_renderer.render("templates/sample.inky", data: { "name" => "Ada" }, options: { inline_css: true, framework_css: true })
mtime_after = cache_file ? File.mtime(cache_file) : nil

failures += check("second render returns the same html as the first (from cache)", second.html == first.html)
failures += check("cache file was not rewritten on the second render (cache hit)", mtime_before == mtime_after)
failures += check("still exactly one cache file after second render", Dir.glob(File.join(cache_dir, "*.json")).length == 1)

# --- 3. Failure path: missing include raises Inky::BuildError ---------------
puts "3. failure path (missing include raises Inky::BuildError)"
threw = false
warnings_on_exception = nil
begin
  renderer.render("templates/broken.inky")
rescue Inky::BuildError => e
  threw = true
  warnings_on_exception = e.warnings
end
failures += check("Inky::BuildError is raised for a missing include", threw)
failures += check("Inky::BuildError exposes a warnings array", warnings_on_exception.is_a?(Array))

# --- cleanup -----------------------------------------------------------
FileUtils.rm_rf(cache_dir) if Dir.exist?(cache_dir)

puts "\n"
if failures.zero?
  puts "All assertions passed."
  exit(0)
end

warn "#{failures} assertion(s) failed."
exit(1)
