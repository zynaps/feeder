FROM ruby:alpine

WORKDIR /

COPY . ./

RUN \
  set -xe && \
  apk add --update --no-cache --virtual .build-deps build-base && \
  bundle install --without development test && \
  apk del .build-deps

EXPOSE 4567/tcp

ENV RACK_ENV="production"

CMD ["ruby", "feeder.rb"]
