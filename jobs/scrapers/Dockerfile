FROM python:3.7-alpine
RUN apk add --update \
    alpine-sdk \
    openssl-dev \
    libxml2-dev \
    libxslt-dev \
    libffi-dev \
    git \
    python3 \
    python3-dev \
    py3-pip \
    build-base \
  && rm -rf /var/cache/apk/*
RUN pip install git+https://github.com/scrapy/scrapyd-client
COPY setup.py /setup.py
COPY scrapy.cfg /scrapy.cfg
COPY scrapers/ scrapers/
COPY run.sh /run.sh
ENTRYPOINT ["/bin/sh", "run.sh"]
