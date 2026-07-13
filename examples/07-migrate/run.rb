# frozen_string_literal: true

# 07 — migrate
#
# Upgrading a v1 Inky template to v2 syntax: <columns large="6"> becomes
# <column lg="6">, <h-line> becomes <divider>, <spacer size="..."> becomes
# <spacer height="...">, class-based button/menu modifiers become
# attributes, and <center><menu>...</menu></center> becomes
# <menu align="center">. migrate_with_details returns both the rewritten
# HTML and a human-readable list of what changed — useful as a one-time
# upgrade script, or as a report to sanity-check before trusting the
# output.

require_relative "../../bootstrap"

dist = inky_example("07-migrate")

legacy = File.read(File.join(__dir__, "legacy-v1.inky"))

result = Inky.migrate_with_details(legacy)

puts "Changes (#{result[:changes].length}):"
result[:changes].each { |change| puts "  - #{change}" }

# Write the migrated v2 template to disk — this is what you'd commit in
# place of the old file after reviewing the change list above.
File.write(File.join(dist, "migrated.inky"), result[:html])

# Prove the migrated template still builds cleanly end to end.
built = Inky.build(result[:html], base_path: __dir__)
File.write(File.join(dist, "email.html"), built.html)

built.warnings.each { |w| warn "warning: #{w}" }

puts
puts "migrated.inky: #{result[:html].bytesize} bytes"
puts "email.html:    #{built.html.bytesize} bytes"
