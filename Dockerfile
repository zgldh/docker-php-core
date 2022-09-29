FROM php:7.0.33-fpm

LABEL version="7.0.33-fpm" \
  description="An image of PHP 7.0.33-fpm with extended modules and Supercronic"

RUN apt-get update && apt-cache show supervisor && apt-get install -y \
    supervisor \
    libcurl3-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libpq-dev \
    libmcrypt-dev\
    libxml2-dev\
    libxslt-dev\
    libpng-dev \
    libjpeg-dev \
    libzip-dev zip unzip cron  && \
    apt-get clean

RUN chmod -R 777 /var/run /var/log

RUN docker-php-ext-configure gd \
  --enable-gd-native-ttf \
  --with-freetype-dir=/usr/include/freetype2 \
  --with-png-dir=/usr/include \
  --with-jpeg-dir=/usr/include \
  && docker-php-ext-install -j$(nproc) gd \
  # Install curl
  && docker-php-ext-install curl \
  # Install the zip extension
  && docker-php-ext-install zip \
  # BCMath PHP Extension
  && docker-php-ext-install bcmath \
  # Mbstring PHP Extension is already installed
  # PDO PHP Extension
  && docker-php-ext-install pdo pdo_pgsql pdo_mysql

RUN docker-php-ext-install calendar exif \
    gettext mcrypt mysqli pcntl shmop \
    sysvmsg sysvsem sysvshm wddx xsl

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

# composer
COPY --from=composer:2.0 /usr/bin/composer /usr/local/bin/composer
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
RUN composer self-update --2

WORKDIR /etc/php
