# Daftar Pekerjaan (To-Do List)

## 🚀 Otomatisasi Varnish Cache
- [x] **Deteksi Environment**: Implementasi logika untuk mengecek `USE_VARNISH=true` dari `.env`.
- [x] **Konfigurasi Docker**:
    - [x] Menambahkan service Varnish di `docker-compose.yml`.
    - [x] Menggunakan konfigurasi VCL (Varnish Configuration Language) terbaik untuk performa Drupal (High Performance Delivery).
- [x] **Integrasi Drupal**:
    - [x] Otomatis install modul yang dibutuhkan (misal: `varnish_purge`, `purge`) jika `USE_VARNISH=true`.
    - [x] Konfigurasi modul untuk invalidasi cache otomatis saat konten diupdate.

## 🔴 Integrasi Redis (External/IP)
- [x] **Konfigurasi Environment**:
    - [x] Tambahkan variabel ke `.env`: `USE_REDIS`, `REDIS_HOST` (default: `172.17.0.4`), `REDIS_PORT` (default: `6379`), `REDIS_PASSWORD`.
- [x] **Otomatisasi & Logika**:
    - [x] Implementasi pengecekan `USE_REDIS` di `start.sh`.
    - [x] **Jika `USE_REDIS=false`**: Jangan install modul Redis.
    - [x] **Jika `USE_REDIS=true`**:
        - [x] Install dan enable modul `redis` (dan dependensinya).
        - [x] Konfigurasi `settings.php` untuk menggunakan Redis sebagai backend cache.
