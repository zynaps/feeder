#!/usr/bin/env python3

# TODO: check if we have entry content

import os
import redis
import json
from flask import Flask
from feedgen.feed import FeedGenerator

redis = redis.Redis.from_url(os.getenv('REDIS_URL'))

app = Flask(__name__)

@app.route('/<feed>')
def generate_feed(feed):
    feed_base = "feeder:%s" % feed

    fg = FeedGenerator()

    fg.id("http://feeder.zynaps.ru/%s" % feed)
    fg.title(redis.get('%s:title' % feed_base))
    fg.updated(redis.get('%s:updated' % feed_base).decode())

    for entry in redis.lrange("%s:entries" % feed_base, 0, 49):
        try:
            entry = json.loads(entry.decode())

            fe = fg.add_entry()

            fe.id(entry['id'])
            fe.title(entry['title'])
            fe.content(entry['content'])
            fe.link(href = entry['link'])
            fe.updated(entry['updated'])
        except:
            continue

    return fg.atom_str(pretty = True)

if __name__ == '__main__':
    from waitress import serve
    from paste.translogger import TransLogger
    serve(TransLogger(app), host = '0.0.0.0', port = 4567)
