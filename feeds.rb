require 'open-uri'
require 'rss'
require 'nokogiri'
require 'sinatra'

get %r{/zynaps/rutor-filtered}, :provides => 'rss' do
  title_re = %r{
    (?<titles>.*)\s+
    \((?<year>\d+)\)\s+
    (?<label>[\w\s-]+)\s+от\s+
    (?<team>.*)\s+\|\s+
    (?<versions>.*)
  }x

  feed = RSS::Parser.parse(open("http://alt.rutor.info/rss.php?full=1"))

  feed.items.delete_if do |item|
    if meta = item.title.match(title_re)
      titles = meta['titles'].split('/').map(&:strip)
      year = meta['year'].to_i
      label = meta['label']
      versions = meta['versions'].split(/[, ]+/)
      team = meta['team']

      item.title = format("%s (%d) %s %s | %s", titles.join(' / '), year, label, team, versions.join(','))

      next
    end

    true
  end

  feed.to_s
end

get %r{/bogorad/(?<url>(mediagazer|techmeme)\.com/feed.xml)}, :provides => 'rss' do |url|
  feed = RSS::Parser.parse(open("http://#{url}"))

  feed.items.each do |item|
    item.link = Nokogiri::HTML(item.description).xpath("//span/b/a/@href").to_s
  end

  feed.to_s
end
