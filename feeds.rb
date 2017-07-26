require 'open-uri'
require 'rss'
require 'nokogiri'
require 'redis'
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

  feed.items.keep_if do |item|
    meta = item.title.match(title_re)

    next if not meta

    titles = meta['titles'].split('/').map(&:strip)
    year = meta['year'].to_i
    label = meta['label']
    versions = meta['versions'].split(/[, ]+/)
    team = meta['team']

    next if label =~ /(1080|720)p/

    cache = Redis.new
    cache_key = "feeds:rutor-filtered:seen:%s:%d:%s" % [titles.last, year, versions.join(',')]

    next if team !~ /Scarabey/i and cache.get(cache_key)

    cache.set(cache_key, 1)
    cache.expire(cache_key, 60 * 60 * 24 * 3)

    item.title = format("%s (%d) %s %s | %s", titles.join(' / '), year, label, team, versions.join(','))

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
