FROM ruby:alpine
LABEL maintainer="Igor Vinokurov <zynaps@zynaps.ru>"

WORKDIR /app

COPY . ./

RUN \
  set -xe && \
  bundle install --without development test

EXPOSE 4567

CMD ["ruby", "feeder.rb"]
