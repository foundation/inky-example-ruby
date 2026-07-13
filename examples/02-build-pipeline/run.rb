# frozen_string_literal: true

# 02 — build-pipeline
#
# The full pipeline in one call: a shared brand <layout> (which itself
# pulls in the shared header and footer <include>s), a linked SCSS theme,
# and CSS inlining — everything Inky.transform() alone doesn't do.

require_relative "../../bootstrap"

dist = inky_example("02-build-pipeline")

source = File.read(File.join(__dir__, "email.inky"))

# base_path anchors every relative <layout>/<include>/<link> path in the
# template AND in anything it includes (see SUITE.md "Runtime
# requirements" — the layout's own includes resolve against THIS path,
# not against shared/'s location). Passing __dir__ (examples/02-build-pipeline/)
# is why every shared/ reference in email.inky and shared/layout.html uses
# "../../shared/...".
result = Inky.build(source, base_path: __dir__)

File.write(File.join(dist, "email.html"), result.html)

result.warnings.each { |w| warn "warning: #{w}" }

puts "email.html: #{result.html.bytesize} bytes"
