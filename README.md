# Inky Example: Ruby

A minimal example showing how to use the [Inky](https://github.com/foundation/inky) email framework from Ruby via the Fiddle bindings.

> Requires Inky v2. See [installation instructions](https://github.com/foundation/inky).

## Prerequisites

- Ruby >= 2.7
- The `libinky` shared library (build from source: `cargo build -p inky-ffi --release`)

## Quick Start

```bash
bundle install
ruby build.rb
```

## File Structure

```
src/emails/welcome.inky    Source template
data/welcome.json           Sample merge data
dist/                       Built output (generated)
build.rb                    Build script
send.rb                     Email sending example
```

## Building

`ruby build.rb` transforms the Inky template, generates a merged version with sample data, and creates a plain text version.

## Sending

Edit `send.rb` with your SMTP credentials, then:

```bash
ruby send.rb
```

The example uses the [mail](https://github.com/mikel/mail) gem. Install it with `gem install mail`.

## Documentation

- [Getting Started](https://github.com/foundation/inky/blob/develop/docs/getting-started.md)
- [Component Reference](https://github.com/foundation/inky/blob/develop/docs/components.md)
- [Language Bindings](https://github.com/foundation/inky/blob/develop/docs/bindings.md)
