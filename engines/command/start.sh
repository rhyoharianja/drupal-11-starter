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
echo "Waiting for PostgreSQL server..."
export PGPASSWORD="$POSTGRES_PASSWORD"
until psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d postgres -c '\q' > /dev/null 2>&1; do
    echo "Postgres is unavailable - sleeping"
    sleep 2
done

# Create database if it doesn't exist
if ! psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$POSTGRES_DB'" | grep -q 1; then
    echo "Database $POSTGRES_DB does not exist. Creating..."
    log_exec psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE \"$POSTGRES_DB\""
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

echo "Starting PHP-FPM..."
exec php-fpm
