FROM php:7.4.26-fpm

LABEL version="7.4.26-fpm" \
  description="An image to run Laravel 6"

RUN apt-get update && apt-get install -y \
  libfreetype6-dev \
  libjpeg62-turbo-dev \
  libpng-dev \
  libpq-dev \
  libzip-dev zip unzip cron

RUN docker-php-ext-configure gd \
  && docker-php-ext-install -j$(nproc) gd \
  # Install the zip extension
  && docker-php-ext-install zip \
  # BCMath PHP Extension
  && docker-php-ext-install bcmath \
  # Mbstring PHP Extension is already installed
  # PDO PHP Extension
  && docker-php-ext-install pdo pdo_pgsql pdo_mysql  

RUN pecl install -o -f ev redis; \
  rm -rf /tmp/pear \
  && docker-php-ext-enable redis \
  && docker-php-ext-enable ev 
# Tokenizer PHP Extension is already installed
# XML PHP Extension is already installed

# Supercronic
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-amd64 \
  SUPERCRONIC=supercronic-linux-amd64 \
  SUPERCRONIC_SHA1SUM=a2e2d47078a8dafc5949491e5ea7267cc721d67c
RUN curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

# sockets
RUN docker-php-ext-install sockets

# opcache
RUN docker-php-ext-install opcache

# pcntl && event
RUN docker-php-ext-install pcntl
RUN apt-get update && apt-get install -y libevent-dev libssl-dev
RUN pecl install event && \
    echo "extension=event.so" > /usr/local/etc/php/conf.d/event.ini

# swoole
RUN pecl install swoole && \
    echo "extension=swoole.so" > /usr/local/etc/php/conf.d/swoole.ini

# supervisord
RUN apt-cache show supervisor && apt-get update && apt-get install -y supervisor
RUN chmod -R 777 /var/run

WORKDIR /etc/php
