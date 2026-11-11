<?php

declare(strict_types=1);

function wasmCheck(bool $condition, string $message): void
{
    if (!$condition) {
        throw new RuntimeException($message);
    }
}

function wasmTestIncrement(int $value): int
{
    return $value + 1;
}

set_error_handler(static function (int $severity, string $message, string $file, int $line): never {
    throw new ErrorException($message, 0, $severity, $file, $line);
});

$limits = wasm_limits_new(1, 3);
wasmCheck(wasm_limits_min($limits) === 1 && wasm_limits_max($limits) === 3, 'Wasm limits failed');

$engine = wasm_engine_new();
$store = wasm_store_new($engine);
$binary = wat2wasm(<<<'WAT'
(module
  (import "env" "increment" (func $increment (param i32) (result i32)))
  (memory (export "memory") 1 3)
  (func (export "run") (param i32 i32) (result i32)
    local.get 0
    local.get 1
    i32.add
    call $increment))
WAT);
$module = wasm_module_new($store, $binary);
$type = wasm_functype_new(
    new Wasm\Vec\ValType([wasm_valtype_new(WASM_I32)]),
    new Wasm\Vec\ValType([wasm_valtype_new(WASM_I32)])
);
$callback = wasm_func_new($store, $type, 'wasmTestIncrement');
$instance = wasm_instance_new($store, $module, new Wasm\Vec\Extern([wasm_func_as_extern($callback)]));
$exports = wasm_instance_exports($instance);
$memory = wasm_extern_as_memory($exports[0]);
$run = wasm_extern_as_func($exports[1]);
$result = wasm_func_call($run, new Wasm\Vec\Val([wasm_val_i32(20), wasm_val_i32(21)]));
wasmCheck(wasm_val_value($result[0]) === 42, 'Wasm call/callback failed');
wasmCheck(wasm_memory_data_size($memory) === 65536, 'Wasm initial memory size failed');
wasmCheck(wasm_memory_grow($memory, 1), 'Wasm memory growth failed');
wasmCheck(wasm_memory_size($memory) === 2, 'Wasm grown memory size failed');
$view = wasm_memory_data($memory);
$view->setF32(0, 1.5);
wasmCheck($view->getF32(0) === 1.5, 'Wasm float32 memory access failed');
$view->setF64(8, 3.25);
wasmCheck($view->getF64(8) === 3.25, 'Wasm float64 memory access failed');
wasm_functype_delete($type);
wasm_func_delete($callback);
wasm_module_delete($module);
wasm_instance_delete($instance);
wasm_store_delete($store);
wasm_engine_delete($engine);
echo 'Wasm compile, call, PHP callback and memory growth passed', PHP_EOL;
