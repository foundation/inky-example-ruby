# frozen_string_literal: true

# Example: sending example 05's digest email via SMTP using the `mail` gem.
#
# Run `ruby run_all.rb` first (or at least `ruby examples/05-plain-text/run.rb`)
# so dist/05-plain-text/digest.html and digest.txt exist.
#
# Install: gem install mail (or uncomment the gem in the Gemfile)
# Then configure SMTP settings below.
#
# Alternatives:
#   - ActionMailer (Rails)
#   - Postmark: postmark gem
#   - SendGrid: sendgrid-ruby gem

# require "mail"

require "securerandom"

html_path = File.join(__dir__, "dist", "05-plain-text", "digest.html")
text_path = File.join(__dir__, "dist", "05-plain-text", "digest.txt")

unless File.file?(html_path) && File.file?(text_path)
  warn "Missing dist/05-plain-text/digest.{html,txt} — run `ruby run_all.rb` first."
  exit 1
end

html = File.read(html_path)
text = File.read(text_path)

# Mail.defaults do
#   delivery_method :smtp, {
#     address: "smtp.example.com",
#     port: 587,
#     user_name: "your-username",
#     password: "your-password",
#     authentication: :plain,
#     enable_starttls_auto: true,
#   }
# end
#
# mail = Mail.new do
#   from    "digest@northwindcoffee.example"
#   to      "subscriber@example.com"
#   subject "This week at Northwind Coffee"
#
#   text_part do
#     body text
#   end
#
#   html_part do
#     content_type "text/html; charset=UTF-8"
#     body html
#   end
# end
#
# mail.deliver!
# puts "sent"

# What the `mail` gem builds under the hood, spelled out by hand: a
# multipart/alternative message with the plain-text part first (least
# capable first) and the HTML part second, joined by a MIME boundary.
boundary = "nwc-#{SecureRandom.hex(16)}"
message = "From: Northwind Coffee <digest@northwindcoffee.example>\r\n" \
          "To: subscriber@example.com\r\n" \
          "Subject: This week at Northwind Coffee\r\n" \
          "MIME-Version: 1.0\r\n" \
          "Content-Type: multipart/alternative; boundary=\"#{boundary}\"\r\n" \
          "\r\n" \
          "--#{boundary}\r\n" \
          "Content-Type: text/plain; charset=utf-8\r\n" \
          "\r\n" \
          "#{text}\r\n" \
          "--#{boundary}\r\n" \
          "Content-Type: text/html; charset=utf-8\r\n" \
          "\r\n" \
          "#{html}\r\n" \
          "--#{boundary}--\r\n"

puts "SMTP config not set — edit send.rb with your credentials."
puts "HTML part:      #{html.bytesize} bytes"
puts "Text part:       #{text.bytesize} bytes"
puts "Multipart total: #{message.bytesize} bytes"
