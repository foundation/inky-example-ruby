# frozen_string_literal: true

# 08 — outlook-hybrid
#
# Building specifically for Outlook desktop: hybrid: true switches column
# layout from nested tables to div-based columns wrapped in MSO ghost
# tables (Outlook needs the table for layout; every other client gets
# lighter div markup), and bulletproof_buttons: true renders every
# <button> as VML (<v:roundrect>) inside an MSO conditional, falling back
# to a normal table-based button everywhere else. launch.inky also uses
# <outlook>/<not-outlook> directly for a banner that needs genuinely
# different markup per client — see the comment in that file for how the
# MSO conditional-comment pair works.

require_relative "../../bootstrap"

dist = inky_example("08-outlook-hybrid")

source = File.read(File.join(__dir__, "launch.inky"))

result = Inky.build(source, base_path: __dir__, hybrid: true, bulletproof_buttons: true)

File.write(File.join(dist, "launch.html"), result.html)

result.warnings.each { |w| warn "warning: #{w}" }

# Both markers below prove Outlook-specific output actually landed: the
# bulletproof button's VML shape, and at least one MSO conditional comment
# (hybrid columns and the explicit <outlook>/<not-outlook> pair both emit
# these).
mso_count = result.html.scan("[if mso]").length + result.html.scan("[if !mso]").length
endif_count = result.html.scan("[endif]").length

puts "launch.html: #{result.html.bytesize} bytes"
puts "MSO conditional opens: #{mso_count}, closes: #{endif_count}"
puts "v:roundrect present: #{result.html.include?('v:roundrect') ? 'yes' : 'no'}"
