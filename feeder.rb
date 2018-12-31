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
    maker.channel.updated = redis.get('updated')
    maker.channel.about = redis.get('about')

    if redis.llen('entries') > 0
      while (entry = redis.lpop('entries')) do
        entry = JSON.parse(entry)

        maker.items.new_item do |item|
          item.id = entry['id']
          item.title = entry['title']
          item.link = entry['url']
          item.updated = entry['pub_date']
        end
      end
    end
  end

  atom.to_s
end
