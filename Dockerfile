FROM php:7.4.29-fpm

LABEL version="7.4.29-fpm-nginx" \
  description="An image to run Laravel 6"

RUN apt-get update && apt-get install -y \
  libfreetype6-dev \
  libjpeg62-turbo-dev \
  libpng-dev \
  libpq-dev \
  libzip-dev zip unzip cron \
  lua5.4 liblua5.4-0 liblua5.4-dev \
  nginx openssl

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install -j$(nproc) gd \
  # Install the zip extension
  && docker-php-ext-install zip \
  # BCMath PHP Extension
  && docker-php-ext-install bcmath \
  # Mbstring PHP Extension is already installed
  # PDO PHP Extension
  && docker-php-ext-install pdo pdo_pgsql pdo_mysql  

RUN pecl install -o -f ev redis \
  && docker-php-ext-enable redis \
  && docker-php-ext-enable ev 
# Tokenizer PHP Extension is already installed
# XML PHP Extension is already installed

# Supercronic
ENV SUPERCRONIC=supercronic-linux-amd64
# Choose different version for your host.
#ENV SUPERCRONIC=supercronic-linux-386
#ENV SUPERCRONIC=supercronic-linux-arm
#ENV SUPERCRONIC=supercronic-linux-arm64
COPY --from=zgldh/docker-supercronic:0.1.12 "/tmp/${SUPERCRONIC}" "/usr/local/bin/${SUPERCRONIC}"
RUN ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

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

# composer
COPY --from=composer:2.0 /usr/bin/composer /usr/bin/composer
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
RUN composer self-update --2

# Lua with cjson module
RUN cp /usr/include/lua5.4/*.h /usr/include/ && \
    cp /usr/lib/x86_64-linux-gnu/liblua5.4.a /usr/lib/liblua.a && \
    cp /usr/lib/x86_64-linux-gnu/liblua5.4.so /usr/lib/liblua.so && \
    pecl install lua && \
    echo "extension=lua.so" > /usr/local/etc/php/conf.d/lua.ini
RUN cd ~ && curl -fsSLO https://www.kyne.com.au/~mark/software/download/lua-cjson-2.1.0.tar.gz && \
    tar xzvf lua-cjson-2.1.0.tar.gz && \
    cd lua-cjson-2.1.0 && \
    sed -i "s/LUA_VERSION =       5.1/LUA_VERSION =       5.4/" Makefile && \
    sed -i "s/LUA_MODULE_DIR =    \$(PREFIX)\/share\/lua\/\$(LUA_VERSION)/LUA_MODULE_DIR =    \$(PREFIX)\/share\/lua\$(LUA_VERSION)/" Makefile && \
    make && \
    make install && \
    rm ../lua-cjson-2.1.0.tar.gz

RUN rm -rf /tmp/pear && \
    apt-get clean

WORKDIR /etc/php
