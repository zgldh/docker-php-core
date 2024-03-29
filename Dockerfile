FROM php:8.1.2-fpm

LABEL version="8.1.2-fpm" \
  description="An image to run Laravel 9"

RUN apt-get update && apt-cache show supervisor && apt-get install -y \
    supervisor \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libpq-dev \
    libevent-dev libssl-dev \
    libzip-dev zip unzip cron && \
    apt-get clean

RUN chmod -R 777 /var/run

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
  SUPERCRONIC_SHA1SUM=048b95b48b708983effb2e5c935a1ef8483d9e3e
RUN curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

# sockets
RUN CFLAGS="$CFLAGS -D_GNU_SOURCE" docker-php-ext-install sockets

# opcache
RUN docker-php-ext-install opcache

# pcntl && event
RUN docker-php-ext-install pcntl
RUN pecl install event && \
    echo "extension=event.so" > /usr/local/etc/php/conf.d/event.ini

# swoole
RUN pecl install swoole && \
    echo "extension=swoole.so" > /usr/local/etc/php/conf.d/swoole.ini

# wasmer-php
RUN cd /opt &&  \
    curl -fsSLO https://github.com/wasmerio/wasmer-php/archive/refs/tags/1.1.0.tar.gz && \
    tar -xzvf 1.1.0.tar.gz && \
    rm 1.1.0.tar.gz &&  \
    cp -r wasmer-php-1.1.0/ext wasmer-php &&  \
    rm wasmer-php-1.1.0 -rf &&  \
    cd wasmer-php && \
    phpize && \
    ./configure --enable-wasmer && \
    make && \
    make install && \
    docker-php-ext-enable wasm

# composer
COPY --from=composer:2.0 /usr/bin/composer /usr/local/bin/composer
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
RUN composer self-update --2

WORKDIR /etc/php
