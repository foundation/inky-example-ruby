# frozen_string_literal: true

# Shared bootstrap for every example's run.rb.
#
# Loads the `inky-email` binding (via Bundler, which resolves it from a
# local path source pointing at ../inky/bindings/ruby — see the Gemfile)
# and provides inky_example(), a tiny helper that gives each example a
# clean output directory under dist/.
#
# Runtime note (this port's own Task 1 — see SUITE.md "Runtime
# requirements" §1 for the PHP original, and port-ruby-report.md for the
# Ruby-specific write-up): Bundler's `path:` source does not copy, symlink,
# or otherwise indirect the gem — it adds bindings/ruby/lib to $LOAD_PATH
# directly, in place. `Inky::Native.find_library` (lib/inky.rb) locates
# libinky.dylib via a path relative to `__dir__`, so it resolves straight
# to ../inky/target/release/libinky.dylib with no indirection to see
# through at all (simpler than PHP's case, where a symlinked Composer path
# repo needed __DIR__ to resolve through the symlink first — Bundler's
# path source never introduces a symlink in the first place). No explicit
# driver wiring was needed here either.
#
# Separately: Bundler has no equivalent of Composer's
# `minimum-stability: stable` gate. `inky-email`'s gemspec version
# (2.0.0.pre.beta.9) is a prerelease per SemVer, but a `path:` (or `git:`)
# source is resolved directly from the given location regardless of
# prerelease tagging — Bundler does not apply its "prefer released
# versions" preference to path/git sources the way RubyGems proper would
# when resolving from a remote index. `bundle install` picked it up with
# zero extra Gemfile configuration.

require "bundler/setup"
require "inky"
require "fileutils"
require "json"

DIST_ROOT = File.expand_path("dist", __dir__)

# Return the dist output directory for an example, creating it if needed.
#
# Every run.rb starts with:
#   require_relative "../../bootstrap"
#   dist = inky_example("01-quickstart")
def inky_example(name)
  dir = File.join(DIST_ROOT, name)
  FileUtils.mkdir_p(dir)
  dir
end
