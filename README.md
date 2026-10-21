# docker-php-core

PHP images used by ZedIoT and related projects.

## Tags

| Tag | Base | Notes |
| --- | --- | --- |
| `8.1.2-fpm` | `php:8.1.2-fpm` | Laravel 9 image, see `master` branch |
| `7.4.33-fpm-cve-2026-109618-109619` | `php:7.4.33-fpm` + official PHP 7.4 security backport | Hardened PHP 7.4 image for CVE-2026-109618 / CVE-2026-109619, see below |

## 7.4.33-fpm-cve-2026-109618-109619

Hardened PHP 7.4 image. It is based on `php:7.4.33-fpm` (the last PHP 7.4 release)
and rebuilds the PHP core with the official minimal backport published by the
PHP security team for the end-of-life 7.4 branch:

- Branch: https://github.com/php/php-src/tree/PHP-7.4-CVE-2026-109618-109619
- Commit: `712e60f9edfd03f0960fc4fc3c2c375f42b90aa2`
- Advisory: https://www.php.net/archive/2026.php#2026-10-21-5
- GHSA: [GHSA-w8hw-w9fx-j79w](https://github.com/php/php-src/security/advisories/GHSA-w8hw-w9fx-j79w),
  [GHSA-6wmf-4rv5-p3rp](https://github.com/php/php-src/security/advisories/GHSA-6wmf-4rv5-p3rp)

Built-in extensions (versions pinned to the previous
`zgldh/docker-php-core:7.4.28-fpm` image):

- composer 2
- bcmath, gd, zip, pdo, pdo_pgsql, pdo_mysql, sockets, opcache, pcntl
- [ev](https://www.php.net/manual/zh/book.ev.php) 1.1.5, redis 5.3.7
- event 3.0.6, swoole 4.8.6, lua 2.0.7
- Supercronic, supervisord
- lua-cjson 2.1.0

Build and verification details: [docs/CVE-2026-109618-109619.md](docs/CVE-2026-109618-109619.md).

```bash
docker build -t zgldh/docker-php-core:7.4.33-fpm-cve-2026-109618-109619 .
docker run --rm zgldh/docker-php-core:7.4.33-fpm-cve-2026-109618-109619 php -v
```

> **PHP 7.4 is end-of-life.** This image only backports the two CVEs above (and
> keeps the fixes already present in 7.4.33). It is not a substitute for
> migrating to a supported PHP branch.
