FROM python:alpine

WORKDIR /

COPY . ./

RUN \
  set -xe && \
  apk add --no-cache libxml2-dev libxslt-dev && \
  apk add --no-cache --virtual .build-deps build-base && \
  pip3 install --no-cache-dir -r requirements.txt && \
  apk del .build-deps

CMD ["python3", "feeder.py"]
