# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine-nginx:3.23

# set version label
ARG BUILD_DATE
ARG VERSION="hobby"
LABEL build_version="Grocy Fork: RaphaelRoumat/grocy-hobby - Build-date:- ${BUILD_DATE}"
LABEL maintainer="Raphael Roumat"

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    git \
    yarn \
    curl && \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    php85-gd \
    php85-intl \
    php85-ldap \
    php85-pdo \
    php85-pdo_sqlite \
    php85-tokenizer && \
  echo "**** install composer ****" && \
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer && \
  echo "**** configure php-fpm to pass env vars ****" && \
  sed -E -i 's/^;?clear_env ?=.*$/clear_env = no/g' /etc/php85/php-fpm.d/www.conf && \
  grep -qxF 'clear_env = no' /etc/php85/php-fpm.d/www.conf || echo 'clear_env = no' >> /etc/php85/php-fpm.d/www.conf && \
  echo "**** install grocy from custom fork ****" && \
  mkdir -p /app/www && \
  git clone https://github.com/RaphaelRoumat/grocy-hobby.git /app/www && \
  cp -R /app/www/data/plugins /defaults/plugins && \
  echo "**** install composer packages ****" && \
  composer install -d /app/www --no-dev && \
  echo "**** install yarn packages ****" && \
  cd /app/www && \
  yarn install --production && \
  yarn cache clean && \
  printf "Custom Fork version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /usr/bin/composer \
    /tmp/* \
    /root/.cache \
    /root/.composer

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 80 443
VOLUME /config