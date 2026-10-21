# docker-php-core

8.1.2-fpm with
- composer2
- zip unzip
- pdo_pgsql
- pdo_mysql
- redis
- [ev](https://www.php.net/manual/zh/book.ev.php)
- Supercronic
- sockets
- opcache
- pcntl && event
- swoole
- supervisord
- wasmer-php

## Other tags

- [`7.4.33-fpm-cve-2026-109618-109619`](https://github.com/zgldh/docker-php-core/tree/7.4.33-fpm-cve-2026-109618-109619)
  — hardened PHP 7.4 image: `php:7.4.33-fpm` with the official PHP 7.4
  backport for CVE-2026-109618 / CVE-2026-109619, plus the extension set of
  the previous `7.4.28-fpm` image. Sources, vendored patch and verification
  notes live on the `7.4-cve-2026-109618-109619` branch.
