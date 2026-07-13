# frozen_string_literal: true

# 05 — plain-text
#
# Every transactional/marketing email should ship with a plain-text
# alternative for clients that prefer it (and for spam filters that
# penalize HTML-only mail). The plain_text: true option asks Inky.build
# to derive one from the same source, alongside the HTML.

require_relative "../../bootstrap"

dist = inky_example("05-plain-text")

source = File.read(File.join(__dir__, "digest.inky"))

result = Inky.build(source, base_path: __dir__, plain_text: true)

File.write(File.join(dist, "digest.html"), result.html)
# With plain_text enabled, result.text holds the derived plain-text
# version — the same content, tags and styling stripped, ready to be the
# text/plain part of a multipart email (see send.rb in the repo root).
File.write(File.join(dist, "digest.txt"), result.text)

puts "digest.html: #{result.html.bytesize} bytes"
puts "digest.txt:  #{result.text.bytesize} bytes"
