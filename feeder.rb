require 'redis'
require 'redis-namespace'
require 'json'
require 'rss'
require 'sinatra'

get %r{/(?<feed>\w+)}, provides: 'atom' do |feed|
  redis = Redis::Namespace.new("feeder:#{feed}", redis: Redis.new)

  atom = RSS::Maker.make('atom') do |maker|
    maker.channel.id = "http://feeder.zynaps.ru/#{feed}"
    maker.channel.author = redis.get('author') || 'zynaps@zynaps.ru'
    maker.channel.title = redis.get('title')
    maker.channel.updated = redis.get('updated') || Time.now.to_datetime.rfc3339

    redis.lrange('entries', 0, 49).each do |entry|
      entry = JSON.parse(entry)

      maker.items.new_item do |item|
        item.id = entry['id']
        item.title = entry['title']
        item.content.content = entry['content'] if entry['content']
        item.link = entry['link']
        item.updated = entry['updated']
      end
    end
  end

  atom.to_s
end
