
# PHP 7.4.33 with the official PHP 7.4 security backport for
# CVE-2026-109618 (RCE via OOM corruption) and CVE-2026-109619 (RCE via stale
# global state).
#
# PHP 7.4 is end-of-life and no longer receives regular releases. The PHP
# security team published minimal source backports for PHP 7.4, 8.0 and 8.1:
#   https://github.com/php/php-src/tree/PHP-7.4-CVE-2026-109618-109619
#   commit 712e60f9edfd03f0960fc4fc3c2c375f42b90aa2
#   ("Avoid state corruption via bailout", fix GHSA-w8hw-w9fx-j79w and
#   GHSA-6wmf-4rv5-p3rp)
# Advisory: https://www.php.net/archive/2026.php#2026-10-21-5
#
# This image is based on php:7.4.33-fpm (the last 7.4 release, which already
# contains the 7.4.29-7.4.33 security fixes) and rebuilds the PHP core from the
# source tarball bundled in the official image with the backport applied. The
# configure flags are copied verbatim from `php -i` of the official image, so
# the rebuilt runtime differs from php:7.4.33-fpm only by the patch.
#
# The patch is vendored under patches/ for a reproducible, auditable build.
# See docs/CVE-2026-109618-109619.md for verification evidence.
FROM php:7.4.33-fpm

LABEL version="7.4.33-fpm-cve-2026-109618-109619" \
  description="PHP 7.4.33 with the official backport for CVE-2026-109618 / CVE-2026-109619"

COPY patches/php-7.4-CVE-2026-109618-109619.patch /tmp/cve-2026-109618-109619.patch

# Debian 11 (bullseye) reached end of life in 2026 and the security archive is
# no longer served from deb.debian.org. Pin the apt sources to the snapshot the
# official php:7.4.33-fpm image was built from (2022-11-14) so builds stay
# reproducible and the installed libraries match the base image.
RUN set -eux; \
    sed -i \
        -e 's|^deb http://deb.debian.org/debian bullseye main$|deb http://snapshot.debian.org/archive/debian/20221114T000000Z bullseye main|' \
        -e 's|^deb http://deb.debian.org/debian-security bullseye-security main$|deb http://snapshot.debian.org/archive/debian-security/20221114T000000Z bullseye-security main|' \
        -e 's|^deb http://deb.debian.org/debian bullseye-updates main$|deb http://snapshot.debian.org/archive/debian/20221114T000000Z bullseye-updates main|' \
        /etc/apt/sources.list; \
    printf 'Acquire::Check-Valid-Until "false";\n' > /etc/apt/apt.conf.d/99snapshot; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        bison \
        libargon2-dev \
        libcurl4-openssl-dev \
        libonig-dev \
        libreadline-dev \
        libsodium-dev \
        libsqlite3-dev \
        libssl-dev \
        libxml2-dev \
        zlib1g-dev; \
    docker-php-source extract; \
    cd /usr/src/php; \
    patch --batch --forward -p1 < /tmp/cve-2026-109618-109619.patch; \
    gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
    debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
    ./configure \
        --build="$gnuArch" \
        --with-config-file-path="$PHP_INI_DIR" \
        --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
        --enable-option-checking=fatal \
        --with-mhash \
        --with-pic \
        --enable-ftp \
        --enable-mbstring \
        --enable-mysqlnd \
        --with-password-argon2 \
        --with-sodium=shared \
        --with-pdo-sqlite=/usr \
        --with-sqlite3=/usr \
        --with-curl \
        --with-iconv \
        --with-openssl \
        --with-readline \
        --with-zlib \
        --disable-phpdbg \
        --with-pear \
        --with-libdir="lib/$debMultiarch" \
        --disable-cgi \
        --enable-fpm \
        --with-fpm-user=www-data \
        --with-fpm-group=www-data; \
    make -j"$(nproc)"; \
    make install; \
    docker-php-source delete; \
    rm -f /tmp/cve-2026-109618-109619.patch

# Same packages/extensions as zgldh/docker-php-core:7.4.28-fpm. Extension
# versions are pinned to the versions that image shipped, so moving to 7.4.33
# does not silently change extension behavior.
RUN apt-get -o Acquire::Check-Valid-Until=false update && apt-get install -y --no-install-recommends \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libpq-dev \
        libzip-dev \
        zip unzip cron \
        lua5.4 liblua5.4-0 liblua5.4-dev \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd \
 && docker-php-ext-install -j"$(nproc)" gd \
 && docker-php-ext-install -j"$(nproc)" zip \
 && docker-php-ext-install -j"$(nproc)" bcmath \
 && docker-php-ext-install -j"$(nproc)" pdo pdo_pgsql pdo_mysql

# pecl.php.net's channel REST endpoint has been intermittently returning
# "No releases available", so download the pinned tarballs directly (with
# retries) and install them from the local files.
RUN set -eux; \
    cd /tmp; \
    curl -fsSL --retry 5 --retry-delay 3 -o ev-1.1.5.tgz https://pecl.php.net/get/ev-1.1.5.tgz; \
    curl -fsSL --retry 5 --retry-delay 3 -o redis-5.3.7.tgz https://pecl.php.net/get/redis-5.3.7.tgz; \
    pecl install -o -f /tmp/ev-1.1.5.tgz /tmp/redis-5.3.7.tgz; \
    docker-php-ext-enable redis ev; \
    rm -f /tmp/ev-1.1.5.tgz /tmp/redis-5.3.7.tgz

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
RUN docker-php-ext-install -j"$(nproc)" sockets

# opcache
RUN docker-php-ext-install -j"$(nproc)" opcache

# pcntl
RUN docker-php-ext-install -j"$(nproc)" pcntl

# event
RUN apt-get -o Acquire::Check-Valid-Until=false update && apt-get install -y --no-install-recommends libevent-dev libssl-dev \
 && rm -rf /var/lib/apt/lists/*
RUN set -eux; \
    cd /tmp; \
    curl -fsSL --retry 5 --retry-delay 3 -o event-3.0.6.tgz https://pecl.php.net/get/event-3.0.6.tgz; \
    pecl install -o -f /tmp/event-3.0.6.tgz; \
    printf 'extension=event.so\n' > /usr/local/etc/php/conf.d/event.ini; \
    rm -f /tmp/event-3.0.6.tgz

# swoole
RUN set -eux; \
    cd /tmp; \
    curl -fsSL --retry 5 --retry-delay 3 -o swoole-4.8.6.tgz https://pecl.php.net/get/swoole-4.8.6.tgz; \
    pecl install -o -f /tmp/swoole-4.8.6.tgz; \
    printf 'extension=swoole.so\n' > /usr/local/etc/php/conf.d/swoole.ini; \
    rm -f /tmp/swoole-4.8.6.tgz

# supervisord
RUN apt-get -o Acquire::Check-Valid-Until=false update && apt-get install -y --no-install-recommends supervisor \
 && rm -rf /var/lib/apt/lists/*
RUN chmod -R 777 /var/run

# composer
COPY --from=composer:2.0 /usr/bin/composer /usr/bin/composer
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
RUN composer self-update --2

# Lua with cjson module
RUN set -eux; \
    cp /usr/include/lua5.4/*.h /usr/include/; \
    cp /usr/lib/x86_64-linux-gnu/liblua5.4.a /usr/lib/liblua.a; \
    cp /usr/lib/x86_64-linux-gnu/liblua5.4.so /usr/lib/liblua.so; \
    cd /tmp; \
    curl -fsSL --retry 5 --retry-delay 3 -o lua-2.0.7.tgz https://pecl.php.net/get/lua-2.0.7.tgz; \
    pecl install -o -f /tmp/lua-2.0.7.tgz; \
    printf 'extension=lua.so\n' > /usr/local/etc/php/conf.d/lua.ini; \
    rm -f /tmp/lua-2.0.7.tgz

# lua-cjson 2.1.0 vendored under vendor/ because the historical download host
# (kyne.com.au) is no longer serving the tarball. sha256:
# 8449f696d56edf27a318daa315d324757bf68120306fecbeb28a66b86077d8cd
COPY vendor/lua-cjson-2.1.0.tar.gz /tmp/
RUN set -eux; \
    cd /tmp; \
    tar xzf lua-cjson-2.1.0.tar.gz; \
    cd lua-cjson-2.1.0; \
    sed -i "s/LUA_VERSION =       5.1/LUA_VERSION =       5.4/" Makefile; \
    sed -i "s/LUA_MODULE_DIR =    \$(PREFIX)\/share\/lua\/\$(LUA_VERSION)/LUA_MODULE_DIR =    \$(PREFIX)\/share\/lua\$(LUA_VERSION)/" Makefile; \
    make; \
    make install; \
    rm -rf /tmp/lua-cjson-2.1.0 /tmp/lua-cjson-2.1.0.tar.gz

RUN docker-php-source delete \
 && apt-get clean \
 && rm -rf /tmp/pear /var/lib/apt/lists/*

WORKDIR /etc/php
