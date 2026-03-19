# Example: sending the built email using the mail gem.
#
# Install: gem install mail (or uncomment in Gemfile)
# Then configure SMTP settings below.
#
# Alternatives:
#   - ActionMailer (Rails)
#   - Postmark: postmark gem
#   - SendGrid: sendgrid-ruby gem

# require "mail"

html = File.read("dist/welcome-merged.html")
text = File.read("dist/welcome.txt")

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
#   from    "noreply@example.com"
#   to      "alice@example.com"
#   subject "Welcome!"
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

puts "SMTP config not set — edit send.rb with your credentials."
puts "HTML length: #{html.length} bytes"
puts "Text length: #{text.length} bytes"
