# frozen_string_literal: true

# 01 — quickstart
#
# The smallest possible thing Inky does: turn responsive-grid markup
# (<container>, <row>, <column>, <button>, ...) into the table-based HTML
# email clients actually render. One call, no layout, no theme, no data.

require_relative "../../bootstrap"

dist = inky_example("01-quickstart")

# The whole template: a shipping-notice snippet with one button component.
source = File.read(File.join(__dir__, "template.inky"))

# Inky.transform is the bare component-to-table conversion — no layout
# resolution, no SCSS, no data merge. It's the one call this example uses.
html = Inky.transform(source)

File.write(File.join(dist, "output.html"), html)

# The <button> component alone expands into several lines of nested table
# markup (bulletproof <table class="button">), so the transformed output
# is noticeably larger than the source even for a tiny template.
puts "template.inky: #{source.bytesize} bytes"
puts "output.html:   #{html.bytesize} bytes"
