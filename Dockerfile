FROM php:8.5.12-fpm

LABEL version="8.5.12-fpm" \
  description="PHP 8.5 FPM with extensions for Laravel and long-running workers"

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      supervisor \
      libfreetype6-dev \
      libjpeg62-turbo-dev \
      libpng-dev \
      libpq-dev \
      libevent-dev \
      libssl-dev \
      libzip-dev zip unzip cron; \
    rm -rf /var/lib/apt/lists/*

# Mbstring, PDO, Tokenizer, XML and (since PHP 8.5) OPcache are built into the base image.
RUN set -eux; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j"$(nproc)" gd zip bcmath pdo_pgsql pdo_mysql sockets pcntl

# Pin stable versions with PHP 8.5 support; load event after sockets.
RUN set -eux; \
    pecl install ev-1.2.3 redis-6.3.0 </dev/null; \
    docker-php-ext-enable ev redis; \
    pecl install event-3.2.0 </dev/null; \
    docker-php-ext-enable --ini-name zz-event.ini event; \
    pecl install swoole-6.2.5 </dev/null; \
    docker-php-ext-enable swoole; \
    rm -rf /tmp/pear

# Supercronic (linux/amd64, matching the published image platform).
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.51/supercronic-linux-amd64 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA256=cc232108374e8e2b537045f2d5eaa1229f619db314c3ba6a14d38b35dc0aa123
RUN set -eux; \
    curl -fsSLo /usr/local/bin/supercronic "$SUPERCRONIC_URL"; \
    echo "${SUPERCRONIC_SHA256}  /usr/local/bin/supercronic" | sha256sum -c -; \
    chmod +x /usr/local/bin/supercronic; \
    ln -s /usr/local/bin/supercronic "/usr/local/bin/${SUPERCRONIC}"

# wasmer-php: correct floating-point parameter types for modern PHP/GCC.
COPY patches/wasmer-php-1.1.0-php85.patch /tmp/wasmer-php.patch
RUN set -eux; \
    cd /opt; \
    curl -fsSLo wasmer-php.tar.gz https://github.com/wasmerio/wasmer-php/archive/refs/tags/1.1.0.tar.gz; \
    tar -xzf wasmer-php.tar.gz; \
    rm wasmer-php.tar.gz; \
    cp -r wasmer-php-1.1.0/ext wasmer-php; \
    rm -rf wasmer-php-1.1.0; \
    cd wasmer-php; \
    patch -p1 < /tmp/wasmer-php.patch; \
    rm /tmp/wasmer-php.patch; \
    phpize; \
    CPPFLAGS="-I/opt/wasmer-php/include" ./configure --enable-wasm; \
    make -j"$(nproc)"; \
    make install; \
    docker-php-ext-enable wasm

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

WORKDIR /etc/php
