FROM php:7.4.28-fpm

LABEL version="7.4.28-fpm" \
  description="An image to run Laravel 6"

RUN apt-get update && apt-get install -y \
  libfreetype6-dev \
  libjpeg62-turbo-dev \
  libpng-dev \
  libpq-dev \
  libzip-dev zip unzip cron \
  lua5.4 liblua5.4-0 liblua5.4-dev

RUN docker-php-ext-configure gd \
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
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-amd64 \
  SUPERCRONIC=supercronic-linux-amd64 \
  SUPERCRONIC_SHA1SUM=048b95b48b708983effb2e5c935a1ef8483d9e3e
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

# composer
COPY --from=composer:2.0 /usr/bin/composer /usr/bin/composer
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
RUN composer self-update --2

# Lua with cjson module
RUN cp /usr/include/lua5.4/*.h /usr/include/ && \
    cp /usr/lib/x86_64-linux-gnu/liblua5.4.a /usr/lib/liblua.a && \
    cp /usr/lib/x86_64-linux-gnu/liblua5.4.so /usr/lib/liblua.so && \
    pecl install lua && \
    echo "extension=lua.so" > /usr/local/etc/php/conf.d/lua.ini \
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
