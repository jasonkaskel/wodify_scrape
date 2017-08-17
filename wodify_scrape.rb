require 'optparse'
require 'cgi'
require 'date'
require 'base64'
require 'csv'
require 'dotenv'
require 'faraday'
require 'json'
require 'pp'

Dotenv.load('.env', '.env.development.local')

options = { to: Date.today }
OptionParser.new do |opts|
  opts.banner = "Usage: wodify_scrape.rb [options]"

  opts.on('--from FROM', 'From date') { |v| options[:from] = Date.parse(v) }
  opts.on('--to TO', 'To date') { |v| options[:to] = Date.parse(v) }
end.parse!
options[:from] ||= options[:to]

HOST = 'https://app.wodify.com'
URL = 'Performance/Whiteboard.aspx'

COOKIES = {
  'osVisitor' => ENV.fetch('osVisitor'),
  'AuthenticationToken' => ENV.fetch('AuthenticationToken')
}

headers = {
  'Cookie' => COOKIES.map { |k, v| "#{k}=#{v}" }.join('; ')
}

puts CSV.generate_line(['date','workout'])
(options[:from]..options[:to]).each do |date|
  $stderr.print "#{date}  \r"
  next if date.sunday?

  body = {
    "AthleteTheme_wtLayout$block$wtSubNavigation$wtWhiteboardDate" => date,
    '__EVENTTARGET' => ENV.fetch('__EVENTTARGET'),
    '__AJAX' => ENV.fetch('__AJAX'),
    '__AJAXEVENT' => ENV.fetch('__AJAXEVENT'),
  }.merge(JSON.parse(Base64.decode64(ENV.fetch('BASE64_ENCODED_BODY_JSON'))))

  conn = Faraday.new(url: HOST) do |faraday|
    faraday.request  :url_encoded             # form-encode POST params
    faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
  end

  response = conn.post do |req|
    req.url "/#{URL}?_ts=#{Time.now.getutc}"
    req.headers = headers
    req.body = body
  end

  encoded_response = response.body
  to_match = /.*ListRecords.*?>(.*<\\\/span>)/
  matched = to_match.match(encoded_response)

  next unless matched

  html = matched[1]
  strings = html.split(/<.*?>/).reject(&:empty?)
  strings = strings.map do |str|
    CGI.unescapeHTML(str
                      .each_char
                      .map { |char| char.codepoints.first > 127 ? ' ' : char }
                      .join
                      .gsub(/ {2,}/,' '))
  end

  puts CSV.generate_line([date] + strings)
end
