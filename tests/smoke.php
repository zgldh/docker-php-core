<?php

declare(strict_types=1);

function check(bool $condition, string $message): void
{
    if (!$condition) {
        throw new RuntimeException($message);
    }
}

set_error_handler(static function (int $severity, string $message, string $file, int $line): never {
    throw new ErrorException($message, 0, $severity, $file, $line);
});

$expectedVersion = $argv[1] ?? '8.5.12';
check(PHP_VERSION === $expectedVersion, 'Unexpected PHP version: ' . PHP_VERSION);
foreach (['bcmath', 'gd', 'zip', 'PDO', 'pdo_mysql', 'pdo_pgsql', 'mbstring',
    'tokenizer', 'xml', 'sockets', 'Zend OPcache', 'pcntl', 'ev', 'event', 'redis', 'swoole', 'wasm'] as $extension) {
    check(extension_loaded($extension), 'Missing extension: ' . $extension);
}
foreach (['ev' => '1.2.3', 'event' => '3.2.0', 'redis' => '6.3.0', 'swoole' => '6.2.5'] as $extension => $version) {
    check(phpversion($extension) === $version, 'Unexpected extension version: ' . $extension);
}
check(bcadd('1.2', '2.3', 1) === '3.5', 'BCMath failed');
check(gd_info()['JPEG Support'] && gd_info()['FreeType Support'], 'GD JPEG/FreeType support missing');
check(in_array('mysql', PDO::getAvailableDrivers(), true), 'MySQL PDO driver missing');
check(in_array('pgsql', PDO::getAvailableDrivers(), true), 'PostgreSQL PDO driver missing');
$socket = socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
check($socket instanceof Socket, 'Socket creation failed');
socket_close($socket);
$base = new EventBase();
check($base->getMethod() !== '', 'EventBase initialization failed');
check((new Redis()) instanceof Redis, 'Redis initialization failed');
check(class_exists(EvLoop::class), 'EvLoop class missing');
check(class_exists(Swoole\Coroutine::class), 'Swoole coroutine class missing');
check(ini_get('max_multipart_body_parts') !== false, 'Multipart limit setting missing');
echo 'PHP version, extensions and basic operations passed', PHP_EOL;
