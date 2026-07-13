# Inky Example Suite: Ruby

Ten runnable, numbered examples showing how to use the [Inky](https://github.com/foundation/inky)
email framework from Ruby, via the `bindings/ruby` Fiddle binding — from the
smallest possible transform up to a transactional-email capstone and a
Liquid/Total-CMS integration.

This is a Stage C port of the flagship PHP example suite
(`inky-example-php`), ported unchanged against the same required output
markers defined in that repo's `SUITE.md` (the language-neutral porting
contract). See `port-ruby-report.md` (in the main `inky` repo's
`.superpowers/sdd/` directory) for this port's own task-by-task notes,
ambiguities, and deviations.

> Requires Inky v2. See the main [inky](https://github.com/foundation/inky) repo.

## Requirements

- Ruby >= 3.0 (developed and verified against 3.2.2; the binding itself
  supports Ruby >= 2.7, but `Liquid::Environment` — used by example 10 —
  needs a current Liquid release, which needs a current Ruby)
- A Rust toolchain, to build the `libinky` shared library:
  ```bash
  cd ../inky && cargo build -p inky-ffi --release
  ```
  (this repo must be checked out as a sibling of `inky/` — the Gemfile's
  local path source for `inky-email`, and the binding's own dylib lookup,
  both assume that layout)
- Bundler, to pull in `inky-email` via a local path source pointing at
  `../inky/bindings/ruby`
- `liquid` (pulled in automatically by `bundle install`) — used only by
  example 10, as the Jinja-family substitute for Twig (Ruby has no Twig
  port — see examples/10-twig-cms/emails/newsletter.inky.liquid's header
  comment for the full substitution rationale)

## 60-second quick start

```bash
cd ../inky && cargo build -p inky-ffi --release   # build libinky once
cd ../inky-example-ruby
bundle install                                    # pulls in inky-email via the path source, plus liquid
ruby run_all.rb                                   # runs every examples/*/run.rb, writes dist/
ruby run_all.rb --verify                          # same, plus greps every output for its required markers
```

`ruby run_all.rb --verify` prints `NN-name: ok` for all ten. Output lands
in `dist/NN-name/` (gitignored).

## The ten examples

| # | Name | Teaches |
|---|------|---------|
| [01-quickstart](examples/01-quickstart) | quickstart | The smallest possible thing Inky does: `Inky.transform` turns a `<button>` into table markup, no layout or data involved. |
| [02-build-pipeline](examples/02-build-pipeline) | build-pipeline | The full `build` call: shared layout, includes, linked SCSS theme, CSS inlining, one call. |
| [03-data-merge](examples/03-data-merge) | data-merge | Merging JSON data into a template: variables, a conditional, and a `{% for %}` loop rendered as real `<tr>` rows. |
| [04-theming](examples/04-theming) | theming | Building the identical template twice with a different linked SCSS theme each time. |
| [05-plain-text](examples/05-plain-text) | plain-text | Deriving a plain-text alternative alongside the HTML for multipart transactional email. |
| [06-validate-gate](examples/06-validate-gate) | validate-gate | Using `Inky.validate` as a CI gate: block on errors, let warnings through. |
| [07-migrate](examples/07-migrate) | migrate | Upgrading a v1 Inky template to v2 syntax programmatically, with a reviewable change report. |
| [08-outlook-hybrid](examples/08-outlook-hybrid) | outlook-hybrid | Hybrid column layout, bulletproof VML buttons, `<outlook>`/`<not-outlook>` branching. |
| [09-transactional](examples/09-transactional) | transactional (capstone) | A real three-email transactional set (welcome, receipt, password reset) built through `EmailRenderer`, a small production-shaped service class. |
| [10-twig-cms](examples/10-twig-cms) | twig-cms | Integrating Inky into a Jinja-family-CMS (Total CMS's shape, ported here with Liquid in place of Twig): both valid processing orders, timed, plus the one `<raw>` rule that makes the fast path safe. |

Run any single example directly, e.g. `ruby examples/03-data-merge/run.rb`
— every `run.rb` is a self-contained, top-to-bottom tutorial with comments
at each decision point.

## For Total CMS / CMS integrators

If you're wiring Inky into a Liquid- or Jinja-family-based CMS (Total CMS
or similar), start at [09-transactional](examples/09-transactional) to
see the production-shaped `EmailRenderer` wrapper
(`src/email_renderer.rb`), then read [10-twig-cms](examples/10-twig-cms)
for the CMS-specific question: should the template engine or Inky run
first? Both orders are implemented, timed, and proven to agree — see that
example's `run.rb` and `newsletter.inky.liquid`'s header comment for the
full trade-off, including the one `<raw>`-plus-`inline_css: false` rule
that makes the faster, build-once-per-template order safe.

## Layout

```
Gemfile                 inky-email via a local path source (../inky/bindings/ruby); liquid
bootstrap.rb             require + inky_example() dist-dir helper, shared by every run.rb
src/email_renderer.rb    small production-shaped render/theme/cache wrapper (example 09; the pattern example 10 adapts for a Liquid CMS)
shared/                  brand layout, includes, SCSS themes used by examples 01-08
examples/NN-name/        one directory per example: run.rb (tutorial) + verify.rb (smoke test)
dist/                    build output (generated, gitignored)
run_all.rb               runs every example (ruby run_all.rb / --verify)
send.rb                  multipart send demo reading example 05's output
```

Examples 09 and 10 each ship their own self-contained `emails/` base-root
tree (`emails/layouts/`, `emails/themes/`, `emails/includes/`, plus the
templates themselves) instead of referencing `shared/` — see each
example's `emails/layouts/main.html` header comment for the resolution
rule this models (the shape a real CMS integration's on-disk template
directory looks like: one root, everything root-relative, no reach-back
into a shared fixtures folder).

## Known limitations / porting notes

- **Example 10 uses Liquid, not Twig.** Twig has no Ruby port. Liquid is
  the pragmatic Jinja-family substitute — same delimiter family, same
  filter-pipe syntax, same whitespace-control dashes, no autoescaping by
  default (matching the PHP original's explicit `autoescape => false`).
  The one required change beyond swapping engines: Twig's built-in
  `|upper` filter became Liquid's built-in `|upcase`. See
  `examples/10-twig-cms/emails/newsletter.inky.liquid`'s header comment
  for the full write-up, including a Liquid-specific quirk found while
  porting this example (its doc comment itself needed Liquid's `{% raw %}`
  tag, not an HTML comment or Liquid's `{% comment %}` tag, to safely
  quote literal `{{ }}`/`{% %}` syntax without confusing Liquid's parser —
  see `port-ruby-report.md` for the full incident).
- **Example 06 is intentionally the one example whose default invocation
  never fails**, even though its whole point is a failing gate — see its
  "runner seam" comment. `run_all.rb` special-cases its exit code the same
  way the PHP original's `build.php` does.
- **`<raw>` doesn't protect against the CSS inliner's own parse.** It
  protects unexpanded template tags from Inky's component-transform HTML5
  parse, but CSS inlining runs a second, separate parse over that
  transform's output, and a still-unexpanded loop isn't safe from *that*
  parse. The workaround (`inline_css: false` on shell builds, used in
  example 10) is documented as a live engine constraint, not something
  papered over silently.
- **Inky's whitespace cleanup passes aren't invariant to processing
  order.** `break_long_lines`/`collapse_closing_tags` normalize whitespace
  around table-structural tags based on whatever document is in front of
  them at the moment they run — so the same logical content can come out
  of engine-first vs. Inky-first with different (but
  rendering-insignificant, per inky-core's own comment) inter-tag
  whitespace. Example 10's correctness check normalizes only that specific
  whitespace class before comparing; everything else is a byte-for-byte
  comparison.

## Documentation

- `port-ruby-report.md` (in the main `inky` repo, under
  `.superpowers/sdd/`) — this port's own task-by-task notes
- The PHP reference suite's `SUITE.md` — the language-neutral porting
  spec (the Stage C contract) all five language ports implement against
- [Getting Started](https://github.com/foundation/inky/blob/develop/docs/getting-started.md)
- [Component Reference](https://github.com/foundation/inky/blob/develop/docs/components.md)
- [Language Bindings](https://github.com/foundation/inky/blob/develop/docs/bindings.md)
