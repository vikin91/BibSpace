FROM alpine:latest as builder

COPY cpanfile /
ENV EV_EXTRA_DEFS -DEV_NO_ATFORK

RUN apk update && \
    apk add perl \
    perl-io-socket-ssl \
    perl-dbd-pg \
    perl-dev \
    perl-dbd-mysql \
    g++ \
    make \
    wget \
    curl \
    git \
    && curl -L https://cpanmin.us | perl - App::cpanminus \
    && cpanm --installdeps --notest . \
    && rm -rf /root/.cpanm/* /usr/local/share/man/*

FROM builder as bibspace-base

RUN mkdir BibSpace
COPY lib/ /BibSpace/lib
COPY bin/ /BibSpace/bin
COPY t/ /BibSpace/t

# Migration 0.5.0 -> 0.5.0-docker
RUN mkdir -p json_data \
  ; cp bibspace_preferences.json json_data/bibspace_preferences.json \
  ; cp bibspace_stats.json json_data/bibspace_stats.json \
  ; exit 0

ENV EV_EXTRA_DEFS -DEV_NO_ATFORK
ENV TZ=Europe/Berlin
RUN apk update \
  && apk add tzdata \
  && mkdir -p /config/etc \
  && cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime \
  && rm -rf /var/cache/apk/*

RUN echo "Europe/Berlin" > /config/etc/timezone
LABEL version="0.6.0"
EXPOSE 8083
HEALTHCHECK --interval=5s --timeout=3s CMD curl --fail http://localhost:8083/system_status || exit 1

FROM bibspace-base as bibspace
# For production
CMD ["BibSpace/bin/bibspace", "daemon", "-m", "production", "-l", "http://*:8083"]

# For development
# CMD ["morbo", "BibSpace/bin/bibspace", "-l", "http://*:8083"]
