require 'redis'
require 'redis-namespace'
require 'json'
require 'rss'
require 'sinatra'

get %r{/(?<feed>\w+)}, provides: 'atom' do |feed|
  redis = Redis::Namespace.new("feeds:#{feed}", redis: Redis.new)

  atom = RSS::Maker.make('atom') do |maker|
    maker.channel.author = redis.get('author')
    maker.channel.title = redis.get('title')
    maker.channel.updated = redis.get('updated') || Time.now.to_s
    maker.channel.about = redis.get('about')

    redis.lrange('entries', 0, 49).each do |entry|
      entry = JSON.parse(entry)

      maker.items.new_item do |item|
        item.id = entry['id']
        item.title = entry['title']
        item.content.content = entry['content'] if entry['content']
        item.link = entry['url']
        item.updated = entry['pub_date']
      end
    end
  end

  atom.to_s
end
