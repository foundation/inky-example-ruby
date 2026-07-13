# frozen_string_literal: true

# 03 — data-merge
#
# Merging JSON data into a template: plain variables ({{ customer.name }}),
# a conditional ({% if gift %}), and a loop over line items. The loop
# lives inside a real HTML <table> for the line items, so it's wrapped in
# <raw> — see the comment in order.inky for why that's required there.

require_relative "../../bootstrap"

dist = inky_example("03-data-merge")

source = File.read(File.join(__dir__, "order.inky"))
data = JSON.parse(File.read(File.join(__dir__, "data.json")))

# The `data:` option turns on MiniJinja merging; without it {{ }} / {% %}
# pass through untouched (useful when an ESP does its own merging).
result = Inky.build(source, base_path: __dir__, data: data)

File.write(File.join(dist, "order.html"), result.html)

result.warnings.each { |w| warn "warning: #{w}" }

puts "order.html: #{result.html.bytesize} bytes"
