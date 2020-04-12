# frozen_string_literal: true

require 'bundler/setup'
require 'benchmark/ips'
require 'jekyll'
require 'jekyll-avatar'

CONTENTS = <<~TEXT
  {% avatar benbalter %}
TEXT
TEMPLATE = Liquid::Template.parse(CONTENTS, :line_numbers => true)

puts ""
puts ENV["TRAVIS_PULL_REQUEST"].inspect.cyan
puts "Skipping since not a pull-request CI build" unless ENV["TRAVIS_PULL_REQUEST"]

Benchmark.ips do |x|
  x.report('pull-request') { TEMPLATE.render }
  x.report('master') { TEMPLATE.render }
  x.hold! 'bench-temp'
  x.compare!
end
