FROM php:7.0.33-fpm

LABEL version="7.0.33-fpm" \
  description="An image of PHP 7.0.33-fpm with extended modules and Supercronic"

RUN apt-get update && apt-cache show supervisor && apt-get install -y \
    supervisor \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libpq-dev \
    libmcrypt-dev\
    libxml2-dev\
    libxslt-dev\
    libzip-dev zip unzip cron  && \
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

# composer
COPY --from=composer:2.0 /usr/bin/composer /usr/local/bin/composer
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
RUN composer self-update --2

WORKDIR /etc/php
