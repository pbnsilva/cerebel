FROM debian:stretch

RUN set -xe \
    && apt-get update \
    && apt-get install --fix-missing -y autoconf \
                          build-essential \
                          curl \
                          git \
                          libffi-dev \
                          libssl-dev \
                          libtool \
                          libxml2 \
                          libxml2-dev \
                          libxslt1.1 \
                          libxslt1-dev \
                          python3 \
                          python3-dev \
                          vim-tiny \
    && apt-get install -y libtiff5 \
                          libtiff5-dev \
                          libfreetype6-dev \
                          libjpeg62-turbo \
                          libjpeg62-turbo-dev \
                          liblcms2-2 \
                          liblcms2-dev \
                          libwebp6 \
                          libwebp-dev \
                          zlib1g \
                          zlib1g-dev \
    && curl -sSL https://bootstrap.pypa.io/get-pip.py | python3 \
    && pip install git+https://github.com/scrapy/scrapy.git \
                   git+https://github.com/scrapy/scrapyd.git \
                   git+https://github.com/scrapy/scrapyd-client.git \
                   git+https://github.com/scrapinghub/scrapy-splash.git \
                   git+https://github.com/scrapinghub/scrapyrt.git \
                   git+https://github.com/python-pillow/Pillow.git \
    && curl -sSL https://github.com/scrapy/scrapy/raw/master/extras/scrapy_bash_completion -o /etc/bash_completion.d/scrapy_bash_completion \
    && echo 'source /etc/bash_completion.d/scrapy_bash_completion' >> /root/.bashrc \
    && apt-get purge -y --auto-remove autoconf \
                                      libffi-dev \
                                      libssl-dev \
                                      libtool \
                                      libxml2-dev \
                                      libxslt1-dev \
    && apt-get purge -y --auto-remove libtiff5-dev \
                                      libfreetype6-dev \
                                      libjpeg62-turbo-dev \
                                      liblcms2-dev \
                                      libwebp-dev \
                                      zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install bs4
RUN pip3 install imgix
RUN pip3 install grpcio
RUN pip3 install --upgrade google-cloud-storage
RUN pip3 install lxml
RUN pip3 install -U spacy
RUN pip3 install python-dateutil
RUN python3 -m spacy download en
ADD ml ml/
RUN pip3 install /ml/.
RUN pip3 install elasticsearch==5.5.3
RUN pip3 install pyfcm
RUN pip3 install --upgrade google-cloud
RUN pip3 install --upgrade google-cloud-bigquery
RUN pip3 install python-slugify
RUN pip3 install --upgrade google-cloud-translate
COPY templates templates/
COPY ./scrapyd.conf /etc/scrapyd/
VOLUME /etc/scrapyd/ /var/lib/scrapyd/
EXPOSE 6800

CMD ["scrapyd", "--pidfile="]
