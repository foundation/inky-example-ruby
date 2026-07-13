# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"

# A small production-shaped wrapper around Inky.build: one theme, one
# template directory, optional shell caching.
#
# The theme is linked per-render by splicing a `<link rel="stylesheet">`
# into the raw template source before it goes to Inky.build — see
# #inject_theme_link for why that has to branch on the template's shape
# (layout-based vs. full-document vs. bare fragment).
#
# This is the class you'd adapt inside a CMS or app — see examples
# 09 (transactional set) and 10 (Twig/Liquid integration, conceptually —
# 10 doesn't call it directly, but mirrors its shell-caching idea by hand).
class EmailRenderer
  def initialize(template_dir, theme_path, cache_dir: nil)
    @template_dir = template_dir
    @theme_path = theme_path
    @cache_dir = cache_dir
  end

  # Build one template. +data+ is merged into the template (MiniJinja,
  # Twig/Liquid-compatible syntax for the simple cases used in this
  # suite). Warnings go to STDERR; failures raise Inky::BuildError
  # (warnings attached).
  #
  # Note: a cache HIT below returns early with an empty warnings array —
  # it never re-runs Inky.build, so it has nothing to report. Warnings are
  # only ever surfaced on the build that originally produced the cached
  # entry; a warm run reporting zero warnings is not itself evidence that
  # the template is warning-clean.
  def render(template, data: {}, options: {})
    source = File.read(File.join(@template_dir, template))

    theme_href = relative_theme_href
    source = inject_theme_link(source, theme_href)

    options = { plain_text: true }.merge(options)
    options = options.merge(data: data) unless data.empty?

    cache_path = nil
    if @cache_dir
      key = Digest::SHA256.hexdigest("#{source}|#{File.read(@theme_path)}|#{JSON.generate(options)}")
      cache_path = File.join(@cache_dir, "#{key}.json")
      if File.file?(cache_path)
        hit = JSON.parse(File.read(cache_path), symbolize_names: true)
        return Inky::BuildResult.new(html: hit[:html], text: hit[:text], warnings: [])
      end
    end

    result = Inky.build(source, base_path: @template_dir, **options)
    result.warnings.each { |warning| warn "warning: #{warning}" }

    if cache_path
      FileUtils.mkdir_p(@cache_dir)
      File.write(cache_path, JSON.generate({ html: result.html, text: result.text }))
    end

    result
  end

  private

  # Splice a `<link rel="stylesheet" href="...">` for the renderer's theme
  # into the raw template source, before it is handed to Inky.build.
  #
  # This has to branch on the *shape* of the incoming template, because a
  # naive source.sub("</head>", ...) — the naive first attempt — silently
  # does nothing on the most common shape in this suite: a layout-based
  # template.
  #
  # Background: every real template here starts with `<layout src="...">`
  # (see shared/layout.html and examples 09/10). inky-core's
  # process_layout (crates/inky-core/src/include.rs) finds that opening
  # tag and keeps only the content AFTER it — anything textually before
  # the tag in the source string is simply discarded, never making it
  # into the resolved document. The `</head>` tag itself lives inside the
  # *layout file*, not in the child template we're given here, so a
  # child-template-only substitution for `</head>` never finds a match: no
  # error, no warning, just a compiled page with no theme. That's the bug
  # this method exists to avoid.
  #
  # The fix relies on two things confirmed empirically against inky-core:
  # (1) content placed immediately after the `<layout ...>` tag is exactly
  # what flows into the layout's `<yield>` slot, so a `<link>` inserted
  # there ends up in the final document; and (2) inky-core's SCSS
  # extractor (extract_scss_sources in crates/inky-core/src/scss.rs) scans
  # the *entire* layout-resolved document for `<link href="*.scss">` — the
  # tag does NOT need to be inside `<head>` to be found, compiled, and
  # stripped. So inserting right after the layout tag is both sufficient
  # and safe.
  #
  # Three cases, in priority order:
  #
  # 1. Layout-based template (`<layout ...>` as the opening tag): insert
  #    the link immediately after that tag's closing `>`. This is the
  #    fixed case above.
  # 2. Full-document template (no `<layout>`, but has a literal `</head>`):
  #    insert the link just before `</head>`. This was the old (and still
  #    correct, for this shape) behavior.
  # 3. Bare fragment (neither of the above): prepend the link to the
  #    source. The SCSS extractor finds and strips a leading `<link>` just
  #    as well as one embedded deeper in the document.
  def inject_theme_link(source, href)
    link = %(<link rel="stylesheet" href="#{href}">)

    if (match = /<layout\s[^>]*>/i.match(source))
      insert_at = match.end(0)
      return source[0...insert_at] + "\n#{link}" + source[insert_at..]
    end

    return source.sub("</head>", "#{link}\n</head>") if source.include?("</head>")

    "#{link}\n#{source}"
  end

  def relative_theme_href
    # Themes live outside template_dir; compute the href base_path resolves.
    # (Verified in Task 1: the pipeline resolves hrefs relative to base_path.)
    theme_real = File.realpath(@theme_path)
    dir_real = File.realpath(@template_dir)
    prefix = "#{dir_real}/"
    return theme_real.delete_prefix(prefix) if theme_real.start_with?(prefix)

    self.class.relative_path(dir_real, theme_real)
  rescue Errno::ENOENT
    # Fall back to a relative traversal computed from the two paths as
    # given, if realpath resolution fails (e.g. a path that doesn't exist
    # yet).
    self.class.relative_path(@template_dir, @theme_path)
  end

  def self.relative_path(from, to)
    from_parts = from.chomp("/").split("/")
    to_parts = to.split("/")
    while !from_parts.empty? && !to_parts.empty? && from_parts.first == to_parts.first
      from_parts.shift
      to_parts.shift
    end
    ("../" * from_parts.length) + to_parts.join("/")
  end
end
