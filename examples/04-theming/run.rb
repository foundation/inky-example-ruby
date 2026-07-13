# frozen_string_literal: true

# 04 — theming
#
# The exact same template, built twice with a different linked SCSS theme
# each time. Two approaches would work here (substitute the href in the
# template source, or ship two <link> lines and strip one); this example
# substitutes a placeholder, because it makes the one line that changes
# between builds explicit at the call site rather than buried in the
# template.

require_relative "../../bootstrap"

dist = inky_example("04-theming")

# promo.inky links "../../shared/themes/__THEME__.scss" — a placeholder,
# not real Inky syntax. Swapping it before each build is what makes the
# two outputs below differ only in theme.
template = File.read(File.join(__dir__, "promo.inky"))

%w[northwind midnight].each do |theme|
  source = template.gsub("__THEME__", theme)
  result = Inky.build(source, base_path: __dir__)
  out_file = File.join(dist, "promo-#{theme}.html")
  File.write(out_file, result.html)
  puts "#{File.basename(out_file)}: #{result.html.bytesize} bytes"
end
