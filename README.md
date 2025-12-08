# Template Docker Drupal 11

Proyek ini adalah template Docker untuk Drupal 11, dirancang untuk pengembangan dengan PostgreSQL, Nginx, dan PHP 8.4. Template ini mencakup instalasi otomatis, konfigurasi dinamis, dan struktur yang dioptimalkan untuk pengembangan Drupal modern.

## 🚀 Memulai

### Prasyarat
- Docker & Docker Compose
- Git

### Instalasi
1.  **Clone repositori**:
    ```bash
    git clone <repository-url>
    cd drupal-template
    ```

2.  **Konfigurasi Environment**:
    Salin `.env.example` ke `.env` (jika belum dilakukan) dan sesuaikan pengaturan jika diperlukan.
    ```bash
    cp .env.example .env
    ```
    Pastikan `HASH_SALT` diatur dengan string acak yang aman.

3.  **Jalankan Environment**:
    ```bash
    docker compose up -d --build
    ```
    Perintah ini akan:
    - Membangun image PHP dan Nginx.
    - Menjalankan container PostgreSQL, PHP, dan Nginx.
    - **Menginstal Drupal secara otomatis** jika belum terinstal.
    - Mengonfigurasi `settings.php` secara dinamis.

4.  **Akses Situs**:
    Buka [http://localhost:8888](http://localhost:8888) di browser Anda.
    - **User Default**: `admin`
    - **Password Default**: `admin` (dapat dikonfigurasi di `.env`)

---

## 📂 Struktur Proyek & Engines

Direktori `engines/` berisi file konfigurasi dan skrip yang menjalankan environment Docker.

### `engines/command/`
- **`start.sh`**: Skrip entrypoint untuk container PHP.
    - **Cek Database**: Menunggu hingga PostgreSQL siap.
    - **Buat DB Otomatis**: Membuat database yang didefinisikan di `.env` jika belum ada.
    - **Instal Otomatis**: Menjalankan `drush site:install` secara otomatis jika Drupal belum terinstal.
    - **Injeksi Konfigurasi**: Menyalin `settings.php` dan memastikan `hash_salt` terpasang.

### `engines/nginx/`
- **`nginx.conf`**: Konfigurasi server Nginx.
    - Dikonfigurasi untuk melayani Drupal.
    - Mem-proxy request PHP ke container `php` pada port 9000.

### `engines/php/`
- **`php.ini`**: Konfigurasi PHP kustom (misalnya, batas memori, ukuran upload).
- **`www.conf`**: Konfigurasi pool PHP-FPM.

### `engines/setting/`
- **`settings.php`**: Template untuk `settings.php` Drupal.
    - **Konfigurasi Dinamis**: Menggunakan `getenv()` untuk membaca kredensial database dan hash salt dari variabel environment.
    - **Teroptimasi**: Dikonfigurasi khusus untuk environment Docker ini.

---

## 📦 Modul Composer

Proyek ini menggunakan Composer untuk mengelola core Drupal dan dependensinya.

### Core
- **`drupal/core-recommended`**: Mengunci dependensi core Drupal ke versi tertentu untuk stabilitas.
- **`drupal/core-composer-scaffold`**: Menyiapkan direktori `web/` (index.php, .htaccess, dll.).
- **`drush/drush`**: Antarmuka baris perintah (CLI) Drupal Shell.

### Modul Contrib & Tema
- **`drupal/admin_toolbar`**: Toolbar administrasi yang ditingkatkan dengan menu drop-down.
- **`drupal/gin`**: Tema administrasi modern.
- **`drupal/gin_toolbar`**: Integrasi toolbar untuk tema Gin.
- **`drupal/gin_login`**: Tampilan halaman login kustom yang sesuai dengan Gin.
- **`drupal/gin_type_tray`**: UI yang ditingkatkan untuk menambahkan tipe konten.
- **`drupal/dashboard`**: Dashboard yang dapat disesuaikan untuk antarmuka admin.

### Kode Kustom (Custom Code)
- **`web/modules/custom/`**: Tempatkan modul kustom Anda di sini. Dilacak oleh Git dan aman dari penimpaan Composer.
- **`web/themes/custom/`**: Tempatkan tema kustom Anda di sini. Dilacak oleh Git dan aman dari penimpaan Composer.

---

## 🐳 Proses Build Docker

Environment ini dibangun menggunakan `docker-compose.yml` dan `Dockerfile`.

### `Dockerfile`
1.  **Base Image**: `php:8.4-fpm`.
2.  **Dependensi**: Menginstal library sistem (`libzip`, `libpng`, `postgresql-client`, dll.).
3.  **Ekstensi**: Menginstal ekstensi PHP yang dibutuhkan oleh Drupal (`gd`, `pdo_pgsql`, `opcache`, `zip`, dll.).
4.  **Composer**: Menyalin binary Composer dari image resmi.
5.  **Drush**: Menginstal Drush secara global.
6.  **Workdir**: Mengatur `/var/www/html` sebagai direktori kerja.

### `docker-compose.yml`
- **Services**:
    - **`php`**: Container aplikasi. Dibangun dari `Dockerfile`. Me-mount root proyek ke `/var/www/html`.
    - **`nginx`**: Web server. Menggunakan `nginx:latest`. Berbagi namespace jaringan dengan `php` (`network_mode: service:php`) untuk komunikasi cepat.
    - **`postgres`**: Database (eksternal atau didefinisikan dalam file compose terpisah, dikonfigurasi via `.env`).
- **Networking**: Menggunakan jaringan bridge default (atau mode service bersama).
- **Persistensi**: `web/modules/custom` dan `web/themes/custom` bertahan di host (persisten).

---

## 🛠 Tips Penggunaan

### Menjalankan Drush
Jalankan perintah Drush di dalam container:
```bash
docker compose exec php vendor/bin/drush status
docker compose exec php vendor/bin/drush cr
```

### Memperbarui Dependensi
Perbarui core Drupal dan modul:
```bash
docker compose exec php composer update
```

### Log
Lihat log untuk pemecahan masalah (troubleshooting):
```bash
docker compose logs -f php
docker compose logs -f nginx
```
