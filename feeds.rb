require 'open-uri'
require 'rss'
require 'nokogiri'
require 'sinatra'

get %r{/bogorad/(?<url>(mediagazer|techmeme)\.com/feed.xml)}, :provides => 'rss' do |url|
  feed = RSS::Parser.parse(open("http://#{url}"))

  feed.items.each do |item|
    item.link = Nokogiri::HTML(item.description).xpath("//span/b/a/@href").to_s
  end

  feed.to_s
end
