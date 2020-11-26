FROM php:7.3-fpm

LABEL version="1.2 with xdebug" \
  description="An image to run Laravel 6"

RUN apt-get update && apt-get install -y \
  libfreetype6-dev \
  libjpeg62-turbo-dev \
  libpng-dev \
  libpq-dev \
  libzip-dev zip unzip cron

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install -j$(nproc) gd \
  # Install the zip extension
  && docker-php-ext-install zip \
  # BCMath PHP Extension
  && docker-php-ext-install bcmath \
  # Mbstring PHP Extension is already installed
  # PDO PHP Extension
  && docker-php-ext-install pdo pdo_pgsql pdo_mysql
# Tokenizer PHP Extension is already installed
# XML PHP Extension is already installed

RUN pecl install -o -f redis; \
  rm -rf /tmp/pear \
  && docker-php-ext-enable redis

COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

# xdebug
RUN pecl install xdebug; \
  docker-php-ext-enable xdebug

WORKDIR /etc/php
