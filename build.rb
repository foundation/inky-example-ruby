require "inky"
require "fileutils"
require "json"

template = File.read("src/emails/welcome.inky")

FileUtils.mkdir_p("dist")

# Build without data merge (template tags pass through)
html = Inky.transform_inline(template)
File.write("dist/welcome.html", html)
puts "built dist/welcome.html"

# Build with data merge
data = File.read("data/welcome.json")
merged = Inky.transform_with_data(template, data)
File.write("dist/welcome-merged.html", merged)
puts "built dist/welcome-merged.html"

# Generate plain text
text = Inky.to_plain_text(merged)
File.write("dist/welcome.txt", text)
puts "built dist/welcome.txt"

# Validate
diagnostics = JSON.parse(Inky.validate(template))
if diagnostics.any?
  puts "\nvalidation warnings:"
  diagnostics.each do |d|
    puts "  [#{d['severity']}] #{d['rule']}: #{d['message']}"
  end
else
  puts "\nno validation issues found"
end
