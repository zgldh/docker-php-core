#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"
php -v
# Startup warnings must fail the test, even when PHP exits successfully.
php -d error_reporting=-1 -d display_errors=stderr -m > /tmp/php-modules.txt 2> /tmp/php-startup-errors.txt
cat /tmp/php-modules.txt
if [ -s /tmp/php-startup-errors.txt ] || grep -Ei 'warning|deprecated|fatal' /tmp/php-modules.txt; then
    cat /tmp/php-startup-errors.txt >&2
    exit 1
fi
php -d error_reporting=-1 -d display_errors=stderr smoke.php "${1:-8.5.12}"
php -d error_reporting=-1 -d display_errors=stderr wasm.php
php-fpm -t
composer --version
supervisord --version
supercronic -version
printf '* * * * * echo ok\n' > /tmp/test-crontab
supercronic -test /tmp/test-crontab

# PHP 8.5.12 has a delayed soft OOM and a separate hard limit, unlike the 7.4 backport.
status=0
php -d memory_limit=32M -d memory_hard_limit_percent=200 -r 'register_shutdown_function(function () { file_put_contents("/tmp/soft-shutdown-ran", "1"); }); str_repeat("x", 40 * 1024 * 1024);' > /tmp/soft-oom.out 2>&1 || status=$?
cat /tmp/soft-oom.out
[ "$status" -eq 255 ]
[ -f /tmp/soft-shutdown-ran ]
grep -q 'Allowed memory size' /tmp/soft-oom.out

# Concatenation uses a non-fallible allocation; tighten the hard limit to make it deterministic.
status=0
php -d memory_limit=32M -d memory_hard_limit_percent=100 -r 'register_shutdown_function(function () { file_put_contents("/tmp/shutdown-ran", "1"); }); $value = str_repeat("x", 16 * 1024 * 1024); $value .= $value;' > /tmp/oom.out 2>&1 || status=$?
cat /tmp/oom.out
[ "$status" -eq 137 ]
[ ! -f /tmp/shutdown-ran ]
grep -q 'Hard memory limit' /tmp/oom.out

echo 'Image smoke test passed'
