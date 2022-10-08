FROM php:8.0.24-fpm

LABEL version="8.0.24-fpm" \
  description="An image to run Laravel 6"

RUN apt-get update && apt-cache show supervisor && apt-get install -y \
    supervisor \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libpq-dev \
    libevent-dev libssl-dev \
    libmcrypt-dev \
    libxslt-dev \
    libzip-dev zip unzip cron nginx && \
    apt-get clean

RUN chmod -R 777 /var/run /var/log

RUN pecl install mcrypt-1.0.5

RUN docker-php-ext-configure gd \
  --with-freetype \
  && docker-php-ext-install -j$(nproc) gd \
  # Install the zip extension
  && docker-php-ext-install zip \
  # BCMath PHP Extension
  && docker-php-ext-install bcmath \
  # Mbstring PHP Extension is already installed
  # PDO PHP Extension
  && docker-php-ext-install pdo pdo_pgsql pdo_mysql

RUN docker-php-ext-install calendar exif \
  gettext mysqli shmop \
  sysvmsg sysvsem sysvshm xsl \
  && docker-php-ext-enable mcrypt

RUN pecl install -o -f ev redis; \
  rm -rf /tmp/pear \
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

# supervisor, nginx log directory
RUN chown -R www-data:www-data /var/log/supervisor && \
    chown -R www-data:www-data /var/lib/nginx && \
    chown -R www-data:www-data /var/log/nginx

# composer
COPY --from=composer:2.0 /usr/bin/composer /usr/local/bin/composer
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
RUN composer self-update --2

# Set upstream conf and remove the default conf
RUN echo "upstream php-upstream { server 127.0.0.1:9000; }" > /etc/nginx/conf.d/upstream.conf

WORKDIR /etc/php
