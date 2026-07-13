# frozen_string_literal: true

# 10 — twig-cms (ported using Liquid — see the ENGINE SUBSTITUTION NOTE at
# the top of emails/newsletter.inky.liquid's header comment for why: Twig
# has no Ruby port, and Liquid is the pragmatic Jinja-family engine
# available in the Ruby ecosystem, with the same delimiter family,
# filter-pipe syntax, and whitespace-control dashes. See that file's full
# header for the CMS-integrator explanation of Order A vs. Order B and why
# <raw> is load-bearing here (not just defense-in-depth, as in
# 03-data-merge), plus quirks found empirically while building the PHP
# original and reproduced here. This file builds both orders against the
# same 3 recipients, asserts recipient 1 comes out the same document
# either way (see the comment above that check for exactly what "the
# same" means and why), and times both paths.
#
# emails/ is this capstone's self-contained base_path — the same
# base-root convention as 09-transactional's EmailRenderer tree (one
# root, layouts/themes/includes underneath, everything root-relative, no
# traversal outside it — see emails/layouts/main.html for the resolution
# rule). Both Inky.build calls below pass emails/ as base_path.

require_relative "../../bootstrap"
require "liquid"

dist = inky_example("10-twig-cms")
emails_dir = File.join(__dir__, "emails")

# Genuinely Liquid-only: inky's own data: merge (MiniJinja) has no
# mechanism for user-registered filters from Ruby. `| upcase` in the
# template proves an ordinary Liquid built-in filter works; this custom
# filter proves real Liquid extensibility that data: alone cannot reach.
#
# This is trusted, already-authored template content, not user input, so
# there's no autoescaping concern — Liquid, like the Twig build in the
# PHP original (which explicitly sets autoescape => false), does not
# HTML-escape output by default. That keeps the two orders comparable:
# the SAME Liquid environment renders in both orders, so whatever
# escaping policy is in effect applies identically either way; only the
# ORDER of Liquid vs. inky differs between them.
module LoyaltyBadgeFilter
  def loyalty_badge(tier)
    case tier
    when "gold" then "Gold roaster"
    when "silver" then "Silver roaster"
    else "Roaster"
    end
  end
end

liquid_env = Liquid::Environment.build { |env| env.register_filter(LoyaltyBadgeFilter) }

# The template supplies the "$" as static text before the price variable.
products = [
  { "name" => "Colombia Huila, 12oz", "price" => "17.00" },
  { "name" => "Guatemala Antigua, 12oz", "price" => "18.50" },
  { "name" => "Decaf House Blend, 12oz", "price" => "15.00" },
]

recipients = [
  { "first_name" => "Marcus", "tier" => "gold" },
  { "first_name" => "Priya", "tier" => "silver" },
  { "first_name" => "Devon", "tier" => "bronze" },
]

def newsletter_context(recipient, products)
  {
    "subscriber" => recipient,
    "products" => products,
    "shop_url" => "https://northwindcoffee.example/shop",
  }
end

raw_source = File.read(File.join(emails_dir, "newsletter.inky.liquid"))

# inline_css: false in BOTH builds below is load-bearing, not cosmetic —
# see the comment above Order B's build call for why.
build_options = { inline_css: false }

# --- Order A: Liquid first, then a full inky build, once PER RECIPIENT ----
start_a = Process.clock_gettime(Process::CLOCK_MONOTONIC)
template_a = Liquid::Template.parse(raw_source, environment: liquid_env)
order_a_outputs = recipients.map do |recipient|
  liquid_html = template_a.render(newsletter_context(recipient, products))
  Inky.build(liquid_html, base_path: emails_dir, **build_options).html
end
duration_a = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_a) * 1000

# --- Order B: inky ONCE (the shell), then Liquid per recipient ------------
start_b = Process.clock_gettime(Process::CLOCK_MONOTONIC)
# No data: option: Liquid's {{ }} and {% %} pass through untouched (same
# no-op behavior as 03-data-merge without data:). The <raw>-wrapped loop
# is the part that would otherwise be corrupted by HTML5 table
# foster-parenting — see the header comment in newsletter.inky.liquid.
#
# inline_css: false here (and, to match, in Order A above too) works
# around a real inky-core limitation found while building the PHP
# original and reproduced here: <raw> only protects its content from the
# FIRST HTML5 parse (component transform). CSS inlining runs a SEPARATE
# parse over that transform's output, and at shell-build time the
# reinjected loop is still literal {% for %}/{% endfor %} text sitting
# beside a <tr> inside <tbody> — which that second parse foster-parents
# out of the table, same failure mode as skipping <raw> entirely, just
# one stage later. Turning off per-tag inlining (framework_css stays on,
# so the compiled theme still ships as a <style> block) sidesteps the
# second parse and keeps both orders byte-comparable. inline_css: true
# remains fine for templates whose data is always fully merged before
# inky ever runs (09-transactional); it's specifically the
# survives-the-build, fill-in-later shape here that needs this.
shell = Inky.build(raw_source, base_path: emails_dir, **build_options).html
shell_template = Liquid::Template.parse(shell, environment: liquid_env)
order_b_outputs = recipients.map { |recipient| shell_template.render(newsletter_context(recipient, products)) }
duration_b = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_b) * 1000

recipients.each_with_index do |_recipient, i|
  n = i + 1
  File.write(File.join(dist, "order-a-#{n}.html"), order_a_outputs[i])
  File.write(File.join(dist, "order-b-#{n}.html"), order_b_outputs[i])
end

# The correctness claim: recipient 1 must be the same document either way
# inky and Liquid are ordered. The PHP original found a real, reproducible
# divergence here while building this example: inky's pipeline-level
# cleanup passes (break_long_lines / collapse_closing_tags in
# inky-core's pipeline.rs) insert or fold newlines around every
# <table>/<tbody>/<tr>/<td>/<th> tag, unconditionally, on whatever
# document is in front of them at the moment they run. In Order A that's
# the FULLY-EXPANDED 3-row document (Liquid ran first), so all 3 rows get
# normalized together in one pass. In Order B it's the ONE-ROW shell
# (inky ran first, before Liquid had anything to expand) — that single
# row gets normalized once, and then Liquid's blind per-recipient text
# repetition duplicates it verbatim, with no further inky pass afterward
# to reconcile the seams between copies. The row boundaries can end up
# whitespace-differently-normalized between the two orders as a result —
# a genuine engine-level finding (see SUITE.md's "10-twig-cms:
# engine-level findings" subsection in the PHP reference suite, and
# port-ruby-report.md for this port's own confirmation), not something
# papered over here.
#
# It's ALSO exactly the whitespace inky-core's own break_long_lines
# comment calls out as safe to disturb: "Whitespace between table
# elements ... is ignored by email clients." So the comparison below
# normalizes only that — collapsing runs of whitespace strictly BETWEEN a
# closing '>' and the next '<' — before comparing. Any real content or
# structural difference (attributes, text, tag order, row count) still
# fails this check; only inter-tag padding is treated as insignificant,
# on inky's own authority. dist/ still holds the RAW, un-normalized
# output from both orders so the actual whitespace diff can be inspected
# directly.
def collapse_insignificant_table_whitespace(html)
  html.gsub(/>\s+</, "><")
end

normalized_a = collapse_insignificant_table_whitespace(order_a_outputs[0])
normalized_b = collapse_insignificant_table_whitespace(order_b_outputs[0])
identical = normalized_a == normalized_b
puts "recipient 1 identical between orders (ignoring inter-tag whitespace): " \
     "#{identical ? 'yes' : 'NO — DIVERGENCE'}"
unless identical
  warn "10-twig-cms: order-a-1.html and order-b-1.html diverged — see dist/10-twig-cms/ for a diff"
  exit 1
end

printf("orderA: %.2f ms, orderB: %.2f ms (shell built once)\n", duration_a, duration_b)
