FROM ruby:alpine
LABEL maintainer="Igor Vinokurov <zynaps@zynaps.ru>"

WORKDIR /

COPY . ./

RUN \
  set -xe && \
  bundle install --without development test

EXPOSE 4567/tcp

ENV RACK_ENV="production"

CMD ["ruby", "feeder.rb"]
