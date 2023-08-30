require "redis"
require "redis-namespace"
require "json"
require "rss"
require "sinatra"

get %r{/(?<feed>\w+)}, provides: "atom" do |feed|
  redis = Redis::Namespace.new("feeder:#{feed}", redis: Redis.new)

  halt(404) if !redis.exists?("entries")

  atom = RSS::Maker.make("atom") do |maker|
    maker.channel.id = "http://feeder.zynaps.ru/#{feed}"
    maker.channel.author = redis.get("author") || "zynaps@zynaps.ru"
    maker.channel.title = redis.get("title")
    maker.channel.updated = redis.get("updated") || Time.now.to_datetime.rfc3339

    redis.lrange("entries", 0, 49).each do |entry|
      entry = JSON.parse(entry)

      maker.items.new_item do |item|
        item.id = entry["id"]
        item.title = entry["title"]
        if entry["content"]
          item.content.content = entry["content"]
          item.content.type = entry["content_type"] if entry["content_type"]
        end
        item.link = entry["link"]
        item.updated = entry["updated"]
      end
    end
  end

  atom.to_s
end
