<?php

/**
 * @file
 * Drupal site-specific configuration file.
 */

$databases = [];

$settings['hash_salt'] = getenv('HASH_SALT') ?: 'development-only-hash-salt';

$settings['install_profile'] = 'standard';

$databases['default']['default'] = [
  'database' => getenv('POSTGRES_DB'),
  'username' => getenv('POSTGRES_USER'),
  'password' => getenv('POSTGRES_PASSWORD'),
  'prefix' => getenv('POSTGRES_TABLE_PREFIX'),
  'host' => getenv('POSTGRES_HOST'),
  'port' => getenv('POSTGRES_PORT'),
  'namespace' => 'Drupal\\pgsql\\Driver\\Database\\pgsql',
  'driver' => getenv('DB_DRIVER'),
];

$settings['config_sync_directory'] = '../config/sync';

$trusted_hosts = getenv('TRUSTED_HOST_PATTERNS');
if ($trusted_hosts) {
  $settings['trusted_host_patterns'] = array_map('trim', explode(',', $trusted_hosts));
} else {
  $settings['trusted_host_patterns'] = [
    '^localhost$',
    '^127\.0\.0\.1$',
  ];
}

$config['system.logging']['error_level'] = getenv('ERROR_LEVEL') ?: 'verbose';

$config['system.performance']['css']['preprocess'] = filter_var(getenv('CSS_PREPROCESS') ?: FALSE, FILTER_VALIDATE_BOOLEAN);
$config['system.performance']['js']['preprocess'] = filter_var(getenv('JS_PREPROCESS') ?: FALSE, FILTER_VALIDATE_BOOLEAN);

$settings['update_free_access'] = filter_var(getenv('UPDATE_FREE_ACCESS') ?: FALSE, FILTER_VALIDATE_BOOLEAN);

$settings['container_yamls'][] = $app_root . '/' . $site_path . '/' . (getenv('CONTAINER_YAMLS') ?: 'services.yml');

$ignore_dirs = getenv('FILE_SCAN_IGNORE_DIRECTORIES');
if ($ignore_dirs) {
  $settings['file_scan_ignore_directories'] = array_map('trim', explode(',', $ignore_dirs));
} else {
  $settings['file_scan_ignore_directories'] = [
    'node_modules',
    'bower_components',
  ];
}

$settings['entity_update_batch_size'] = (int) (getenv('ENTITY_UPDATE_BATCH_SIZE') ?: 50);
$settings['entity_update_backup'] = filter_var(getenv('ENTITY_UPDATE_BACKUP') ?: TRUE, FILTER_VALIDATE_BOOLEAN);
$settings['migrate_node_migrate_type_classic'] = filter_var(getenv('MIGRATE_NODE_MIGRATE_TYPE_CLASSIC') ?: FALSE, FILTER_VALIDATE_BOOLEAN);

/**
 * Redis Configuration
 */
if (getenv('USE_REDIS') === 'true') {
  $settings['redis.connection']['interface'] = 'PhpRedis';
  $settings['redis.connection']['host'] = getenv('REDIS_HOST') ?: '172.17.0.4';
  $settings['redis.connection']['port'] = getenv('REDIS_PORT') ?: '6379';
  
  if (getenv('REDIS_PASSWORD')) {
    $settings['redis.connection']['password'] = getenv('REDIS_PASSWORD');
  }

  $settings['cache_prefix'] = getenv('REDIS_PREFIX') ?: 'drupal';

  $settings['cache']['default'] = 'cache.backend.redis';
  $settings['container_yamls'][] = 'modules/contrib/redis/example.services.yml';
  $settings['container_yamls'][] = 'modules/contrib/redis/redis.services.yml';
}

if (file_exists($app_root . '/' . $site_path . '/settings.local.php')) {
  include $app_root . '/' . $site_path . '/settings.local.php';
}
