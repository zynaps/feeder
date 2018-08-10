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

  imdb_xpath = "//a/@href[contains(., 'imdb.com/title/')]"
  kpdb_xpath = "//a/@href[contains(., 'kinopoisk.ru/film/')]"

  feed = RSS::Parser.parse(open("http://alt.rutor.info/rss.php?full=1"))

  feed.items.keep_if do |item|
    desc = Nokogiri::HTML(item.description)

    imdb_id = (desc.at_xpath(imdb_xpath).text =~ /\/tt(\d+)\/?$/ ? $1.to_i : nil) rescue nil
    kpdb_id = (desc.at_xpath(kpdb_xpath).text =~ /\/film\/.*?-?(\d+)\/?$/ ? $1.to_i : nil) rescue nil

    cache = Redis.new

    if imdb_id and kpdb_id
      cache.hset("feeds:rutor-filtered:imdb_to_kpdb", imdb_id, kpdb_id)
      cache.hset("feeds:rutor-filtered:kpdb_to_imdb", kpdb_id, imdb_id)
    elsif imdb_id
      kpdb_id = cache.hget("feeds:rutor-filtered:imdb_to_kpdb", imdb_id)
    elsif kpdb_id
      imdb_id = cache.hget("feeds:rutor-filtered:kpdb_to_imdb", kpdb_id)
    end

    meta = item.title.match(title_re)

    next if not meta

    titles = meta['titles'].split('/').map(&:strip)
    year = meta['year'].to_i
    label = meta['label']
    versions = meta['versions'].split(/[, ]+/)
    team = meta['team']

    next if label =~ /((1080|720)p?|-(AVC|HEVC))/

    cache_key = "feeds:rutor-filtered:seen:%s:%d:%s" % [titles.sort.last, year, versions.join(',')]

    if team !~ /Scarabey/i
      next if year < Time.now.year - 2
      next if cache.get(cache_key)
    end

    cache.set(cache_key, 1)
    cache.expire(cache_key, 60 * 60 * 24 * 3)

    if kpdb_id
      data = Nokogiri::XML(open("https://rating.kinopoisk.ru/%s.xml" % kpdb_id))
      imdb_votes = data.xpath('//rating/imdb_rating/@num_vote').text.to_i rescue 0
      imdb_rating = data.xpath('//rating/imdb_rating').text.to_f rescue 0
    else
      imdb_rating = 0.0
    end

    item.title = format("%3.1f/%d %s (%d) %s %s | %s", imdb_rating, imdb_votes, titles.join(' / '), year, label, team, versions.join(','))

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
