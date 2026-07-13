source "https://rubygems.org"

# foundation/inky's Ruby binding is not published to RubyGems; it's pulled
# in via a local path source pointing at ../inky/bindings/ruby, mirroring
# the PHP suite's symlinked Composer path repository (see SUITE.md
# "Runtime requirements" §1 and this repo's own Task-1 note in
# port-ruby-report.md). This repo must be checked out as a sibling of
# `inky/` for the path to resolve.
gem "inky-email", path: "../inky/bindings/ruby"

# Template engine for example 10 (twig-cms). Twig has no Ruby port; Liquid
# is the pragmatic Jinja-family substitute available in the Ruby ecosystem
# — see examples/10-twig-cms/emails/newsletter.inky.liquid's header comment
# for the full substitution rationale and syntax differences from Twig.
gem "liquid", "~> 5.5"

# gem "mail"  # uncomment for sending (see send.rb)
