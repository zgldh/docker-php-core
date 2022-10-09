# docker-php-core

8.0.24-fpm with
- composer2
- zip unzip
- pdo_pgsql
- pdo_mysql
- redis
- [ev](https://www.php.net/manual/zh/book.ev.php)
- opcache
- pcntl && event
- Supercronic
- sockets
- swoole
- supervisord
- wasmer-php
- mcrypt
- intl
- nginx

# Usage
## Dockerfile
```
FROM zgldh/docker-php-core:8.0.24-fpm-nginx
WORKDIR /app

# Copy files and configurations
COPY --chown=www-data:www-data ./ /app
COPY ./your-nginx.conf /etc/nginx/sites-enabled/default
COPY ./your-supervisor.conf /etc/supervisor/conf.d/supervisor.conf
COPY ./your-crontab /etc/supercronictab
COPY ./your-entrypoint.sh /etc/entrypoint/entrypoint.sh

# Composer update
RUN composer update

CMD ["/etc/entrypoint/entrypoint.sh"]
EXPOSE 80

```

## your-nginx.conf
```
server {
    listen 80 default_server;
    server_name  _;
    root /app/public;
    error_log  /dev/stderr;
    access_log /dev/stdout;
 
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";
 
    index index.html index.htm index.php;
 
    charset utf-8;
 
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
 
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }
 
    error_page 404 /index.php;
 
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php-upstream;
        fastcgi_index index.php;
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }
 
    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

## your-supervisor.conf
```
[program:queue]
process_name=%(program_name)s_%(process_num)02d
command=php /app/artisan queue:listen --queue=printer --tries=60
autostart=true
autorestart=true
user=www-data
numprocs=4
redirect_stderr=true
stdout_logfile=/tmp/queue.log

[program:supercronic]
directory=/app
process_name=%(program_name)s_%(process_num)02d
command=supercronic /etc/supercronictab
autostart=true
autorestart=true
user=www-data
numprocs=1
redirect_stderr=true
stdout_logfile=/tmp/queue.log

[group:app]
programs=queue,supercronic
priority=999
```

## your-crontab
```
# cronjob
* * * * * php /app/artisan schedule:run >> /dev/null 2>&1
```

## your-entrypoint
```
#!/bin/bash

supervisord

nginx

php-fpm --nodaemonize

```