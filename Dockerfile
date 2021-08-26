FROM ruby:alpine
LABEL maintainer="Igor Vinokurov <zynaps@zynaps.ru>"

WORKDIR /

COPY . ./

RUN \
  set -xe && \
  apk add --no-cache --virtual .build-deps build-base && \
  bundle install --without development test && \
  apk del .build-deps

EXPOSE 4567/tcp

ENV RACK_ENV="production"

CMD ["ruby", "feeder.rb"]
