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

### 🔄 Migrasi & Upgrade
Panduan lengkap untuk upgrade dari Drupal 8/9/10 atau migrasi ke environment ini dapat dilihat di:
👉 **[Panduan Migrasi & Upgrade (MIGRATION.md)](MIGRATION.md)**

### 📚 Dokumentasi Modul & Konfigurasi
Detail lengkap mengenai modul yang terinstal (Headless, Scheduler, dll) dan konfigurasi `.env` dapat dilihat di:
👉 **[Dokumentasi Modul & Konfigurasi (MODULES_CONFIG.md)](MODULES_CONFIG.md)**

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

## ⚡ Varnish Cache & High Performance

Template ini mencakup integrasi Varnish Cache yang terotomatisasi untuk pengiriman konten berkinerja tinggi (High Performance Delivery).

### Arsitektur
- **Varnish (Frontend)**: Mendengarkan pada port `VARNISH_PORT` (default: 8082). Menerima request dari klien.
- **Nginx (Backend)**: Mendengarkan pada port `NGINX_PORT` (default: 8081). Hanya dapat diakses melalui Varnish (atau langsung untuk debugging).
- **PHP-FPM**: Memproses request dinamis dari Nginx.

### Konfigurasi (.env)
Aktifkan Varnish dengan mengatur variabel berikut di file `.env`:

```bash
USE_VARNISH=true
VARNISH_PORT=8082
NGINX_PORT=8081
```

### Otomatisasi
Saat `USE_VARNISH=true`, skrip `start.sh` akan secara otomatis:
1.  Mengaktifkan modul **`purge`** dan **`varnish_purger`**.
2.  Membuat instance purger Varnish (`drush p:purger-add varnish`).
3.  Mengimpor konfigurasi Drupal yang diperlukan.

### File Konfigurasi
- **VCL**: `engines/varnish/default.vcl` - Konfigurasi Varnish yang dioptimalkan untuk Drupal (mendukung Cache Tags, Ban, Purge).

### Verifikasi
Untuk memverifikasi Varnish bekerja:
```bash
curl -I http://localhost:8082
```
Periksa header respons:
- `X-Cache: HIT` atau `MISS`
- `X-Varnish: <id>`

---

## ⚡ Redis Caching

Template ini mendukung integrasi Redis sebagai backend cache untuk performa tinggi.

### Konfigurasi (.env)
Aktifkan dan konfigurasi Redis di file `.env`:

```bash
USE_REDIS=true
REDIS_HOST=172.17.0.4
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password
REDIS_PREFIX=aleph-redis  # Prefix kustom untuk key Redis
```

### Otomatisasi
Saat `USE_REDIS=true`, skrip `start.sh` akan:
1.  Mengaktifkan modul **`redis`**.
2.  Mengonfigurasi `settings.php` untuk menggunakan Redis sebagai default cache backend.
3.  Menggunakan prefix yang didefinisikan di `REDIS_PREFIX` (default: `drupal`).

### Verifikasi
Untuk memverifikasi koneksi Redis:
```bash
docker compose exec php vendor/bin/drush p:eval "echo \Drupal\Core\Site\Settings::get('cache_prefix');"
# Output harus sesuai dengan REDIS_PREFIX Anda
```

---

## 🔧 Referensi Variabel Environment (.env)

Berikut adalah variabel kunci yang dapat Anda konfigurasi di `.env`:

| Variabel | Deskripsi | Default |
| :--- | :--- | :--- |
| **Database** | | |
| `POSTGRES_DB` | Nama database | `aleph-drupal` |
| `POSTGRES_USER` | User database | `admin` |
| `POSTGRES_PASSWORD` | Password database | `admin` |
| `POSTGRES_HOST` | Host database (IP/Hostname) | `172.17.0.2` |
| **Aplikasi** | | |
| `SITE_NAME` | Nama situs Drupal | `Drupal 11 Docker` |
| `HASH_SALT` | Salt untuk keamanan (Wajib diubah) | `development-only...` |
| `ERROR_LEVEL` | Level error reporting (`verbose`, `hide`) | `verbose` |
| **Layanan** | | |
| `USE_VARNISH` | Aktifkan Varnish Cache | `true` |
| `VARNISH_PORT` | Port publik Varnish | `8082` |
| `NGINX_PORT` | Port publik Nginx | `8081` |
| `USE_REDIS` | Aktifkan Redis Cache | `true` |
| `REDIS_PREFIX` | Prefix key Redis | `drupal` |

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
