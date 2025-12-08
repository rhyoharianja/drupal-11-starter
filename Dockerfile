# Attempt to use PHP 8.5. If not available, fallback to 8.4 or latest stable.
FROM php:8.4-fpm

# Install system dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  build-essential \
  libpng-dev \
  libjpeg62-turbo-dev \
  libfreetype6-dev \
  locales \
  libzip-dev \
  zip \
  jpegoptim optipng pngquant gifsicle \
  vim \
  unzip \
  git \
  curl \
  libpq-dev \
  libonig-dev \
  libxml2-dev \
  libmcrypt-dev \
  postgresql-client \
  sendmail \
  sendmail-bin    && docker-php-ext-install pdo_pgsql \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install zip \
  && docker-php-ext-install exif

RUN docker-php-ext-install pcntl \
  && docker-php-ext-install bcmath

RUN docker-php-ext-install opcache \
  && docker-php-ext-enable opcache

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install -j$(nproc) gd

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install Drush globally
RUN composer global require drush/drush && \
  ln -s /root/.composer/vendor/bin/drush /usr/local/bin/drush

WORKDIR /var/www/html

CMD ["php-fpm"]
