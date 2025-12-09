#!/bin/sh
set -e
export PHP_MEMORY_LIMIT=-1

# Helper function to log and execute commands
log_exec() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Executing: $*"
    "$@"
}

echo "Configuring Drupal settings..."
echo "Using Database Driver: $DB_DRIVER"
# Ensure web/sites/default exists
log_exec mkdir -p web/sites/default

# Copy settings.php from template
if [ -f engines/setting/settings.php ]; then
    echo "Copying settings.php from template..."
    log_exec cp engines/setting/settings.php web/sites/default/settings.php
    
    # Ensure permissions
    log_exec chown www-data:www-data web/sites/default/settings.php
    log_exec chmod 644 web/sites/default/settings.php
fi

# Wait for PostgreSQL server to be ready
echo "Waiting for PostgreSQL server ($POSTGRES_HOST)..."
# export PGPASSWORD="$POSTGRES_PASSWORD"
until PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d postgres -c '\q' > /dev/null 2>&1; do
    echo "Postgres is unavailable - sleeping"
    sleep 2
done

# Create database if it doesn't exist
if ! PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$POSTGRES_DB'" | grep -q 1; then
    echo "Database $POSTGRES_DB does not exist. Creating..."
    log_exec env PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE \"$POSTGRES_DB\""
else
    echo "Database $POSTGRES_DB already exists."
fi

# Wait for database connection (Drush)
echo "Waiting for database connection..."
max_tries=30
count=0
while ! vendor/bin/drush sql:query "SELECT 1" > /dev/null 2>&1; do
    count=$((count+1))
    if [ $count -gt $max_tries ]; then
        echo "Error: Could not connect to database after $max_tries attempts."
        exit 1
    fi
    echo "Waiting for database... ($count/$max_tries)"
    sleep 2
done
echo "Database connected."

# Check if Drupal is already installed
if vendor/bin/drush status --fields=bootstrap | grep -q "Successful"; then
    echo "Drupal is already installed."
    
    echo "Running database updates..."
    log_exec vendor/bin/drush updb -y

    # Sync Site UUID to match config/sync
    if [ -f "config/sync/system.site.yml" ]; then
        echo "Syncing Site UUID from config/sync..."
        # Extract UUID using grep to avoid drush issues
        SYNC_UUID=$(grep "uuid: " config/sync/system.site.yml | awk '{print $2}')
        if [ -n "$SYNC_UUID" ]; then
             echo "Setting active Site UUID to $SYNC_UUID"
             log_exec vendor/bin/drush config:set system.site uuid "$SYNC_UUID" -y
        fi
    fi

    # Delete conflicting entities (Shortcuts) that often cause import issues
    echo "Deleting conflicting shortcut entities..."
    log_exec vendor/bin/drush entity:delete shortcut_set -y || true
    log_exec vendor/bin/drush entity:delete shortcut -y || true

    echo "Importing configuration..."
    log_exec vendor/bin/drush cim -y

    echo "Rebuilding cache..."
    log_exec vendor/bin/drush cr
else
    echo "Installing Drupal ($INSTALL_TYPE profile)..."
    # Run install as www-data to ensure file permissions
    # We rely on settings.php for DB credentials
    log_exec vendor/bin/drush site:install $INSTALL_TYPE \
        --site-name="$SITE_NAME" \
        --account-name="$SUPER_ADMIN" \
        --account-pass="$SUPER_PASSWORD" \
        -y
    
    echo "Importing configuration (initial)..."
    log_exec vendor/bin/drush cim -y
fi

# Varnish Automation
if [ "$USE_VARNISH" = "true" ]; then
    echo "Varnish is enabled. Checking modules..."
    if ! vendor/bin/drush pm:list --status=enabled | grep -q "varnish_purger"; then
        echo "Enabling Varnish Purge modules..."
        log_exec vendor/bin/drush en purge varnish_purger -y
        
        echo "Configuring Varnish Purger..."
        # Create a Varnish purger if it doesn't exist (requires purge_ui or manual config usually, 
        # but we can try to create it via drush p:purger-create if available, or just enable the module and let user config)
        # For now, just enabling is a good start. 
        # Ideally we would set the varnish host/port here too if the module supports simple config via drush.
        # The varnish_purge module usually needs a purger instance created.
        # We can use 'drush p:purger-create varnish' if 'drush_purge' is installed? 
        # Actually purge module provides 'drush p:purger-create'.
        
        # Let's try to create the purger instance
        log_exec vendor/bin/drush p:purger-add varnish --if-not-exists
    fi
fi

# Redis Automation
if [ "$USE_REDIS" = "true" ]; then
    echo "Redis is enabled. Checking modules..."
    if ! vendor/bin/drush pm:list --status=enabled | grep -q "redis"; then
        echo "Enabling Redis module..."
        log_exec vendor/bin/drush en redis -y
    fi
fi

echo "Starting PHP-FPM..."
exec php-fpm
