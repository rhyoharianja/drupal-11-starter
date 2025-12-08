# Dokumentasi Modul & Konfigurasi

Dokumen ini menjelaskan daftar modul yang telah ditambahkan ke proyek ini serta konfigurasi khusus yang telah diterapkan untuk mendukung arsitektur Headless, Moderasi Konten, dan Environment Docker yang fleksibel.

## 📦 Modul yang Ditambahkan

Berikut adalah daftar modul yang telah diinstal via Composer dan fungsinya:

### 1. Headless CMS & API
Modul-modul ini mengubah Drupal menjadi backend API yang kuat untuk aplikasi frontend (React, Vue, Next.js, dll).

*   **`drupal/simple_oauth`**: Menyediakan otentikasi OAuth 2.0 yang aman. Ini adalah standar industri untuk mengamankan API endpoint.
*   **`drupal/jsonapi_extras`**: Memberikan kemampuan untuk memodifikasi output JSON:API standar (misalnya: mengubah nama field, menonaktifkan resource tertentu) agar lebih bersih untuk frontend.
*   **`drupal/decoupled_router`**: Sangat penting untuk aplikasi decoupled. Membantu frontend menerjemahkan path URL (misal `/about-us`) menjadi entity Drupal yang sesuai.
*   **`drupal/consumers`**: Dependensi untuk Simple OAuth, digunakan untuk mendefinisikan klien API (aplikasi consumer).
*   **`drupal/metatag`**: Mengekspos metadata SEO (meta tags) ke dalam respon API, sehingga frontend bisa merender SEO yang baik.
*   **`drupal/pathauto`**: Secara otomatis membuat URL alias yang bersih (SEO-friendly) berdasarkan pola tertentu (misal: `/berita/[judul-berita]`).

### 2. Moderasi & Penjadwalan (Workflow)
Modul-modul ini memberikan kontrol lebih atas publikasi konten.

*   **`drupal/scheduler`**: Memungkinkan editor untuk menjadwalkan kapan konten akan dipublikasikan atau diarsipkan (unpublish) secara otomatis.
*   **`drupal/scheduler_content_moderation_integration`**: Menghubungkan Scheduler dengan Content Moderation (Core). Memungkinkan penjadwalan *perubahan status* (misal: dari "Draft" ke "Published" pada tanggal tertentu).
*   **`drupal/rules`**: Memberikan kemampuan untuk membuat logika "If-Then" (Jika-Maka) tanpa coding. Berguna untuk otomatisasi kompleks.
*   **`drupal/condition_field`**: Memungkinkan field tertentu disembunyikan/ditampilkan berdasarkan nilai field lain di form edit konten.

### 3. Administrasi & UI (Backend Experience)
Modul-modul ini meningkatkan pengalaman pengguna bagi administrator dan editor konten.

*   **`drupal/admin_toolbar`**: Meningkatkan toolbar default dengan menu drop-down yang cepat.
*   **`drupal/gin`**: Tema administrasi modern dengan tampilan yang bersih dan responsif.
*   **`drupal/gin_toolbar`**, **`drupal/gin_login`**, **`drupal/gin_type_tray`**: Modul pendukung untuk tema Gin.
*   **`drupal/dashboard`**: Menyediakan dashboard yang dapat dikustomisasi dengan widget untuk halaman depan admin.

---

## ⚙️ Konfigurasi Tambahan

Proyek ini telah dikonfigurasi agar sangat fleksibel dan dapat diatur melalui **Environment Variables (`.env`)** tanpa perlu mengubah kode PHP.

### 1. File `settings.php`
File `engines/setting/settings.php` (yang disalin ke `web/sites/default/settings.php`) telah dibersihkan dan diparameterisasi sepenuhnya.

#### Database & Keamanan
*   **Database**: Menggunakan `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_HOST`, `POSTGRES_PORT`, `DB_DRIVER`.
*   **Hash Salt**: `HASH_SALT` (Wajib diisi untuk keamanan session).
*   **Trusted Host Patterns**: `TRUSTED_HOST_PATTERNS` (Daftar domain yang diizinkan, dipisahkan koma).

#### Performa & Debugging
*   **Error Level**: `ERROR_LEVEL` (Nilai: `verbose`, `all`, `some`, `none`). Default: `verbose`.
*   **CSS Preprocess**: `CSS_PREPROCESS` (Nilai: `TRUE` atau `FALSE`). Menggabungkan dan meminifikasi CSS.
*   **JS Preprocess**: `JS_PREPROCESS` (Nilai: `TRUE` atau `FALSE`). Menggabungkan dan meminifikasi JS.

#### Konfigurasi Sistem Lainnya
*   **Config Sync Directory**: Diset otomatis ke `../config/sync`.
*   **Update Free Access**: `UPDATE_FREE_ACCESS` (Izinkan akses `update.php` tanpa login).
*   **Container YAMLs**: `CONTAINER_YAMLS` (File service definition tambahan).
*   **File Scan Ignore**: `FILE_SCAN_IGNORE_DIRECTORIES` (Direktori yang diabaikan saat scan file, default: `node_modules,bower_components`).
*   **Entity Update**: `ENTITY_UPDATE_BATCH_SIZE` dan `ENTITY_UPDATE_BACKUP`.
*   **Migrate**: `MIGRATE_NODE_MIGRATE_TYPE_CLASSIC`.

### 2. File `.env`
Semua konfigurasi di atas diatur melalui file `.env`. Pastikan Anda menyalin `.env.example` ke `.env` dan menyesuaikan nilainya.

Contoh konfigurasi di `.env`:
```bash
# Security
HASH_SALT=ganti-dengan-string-acak-yang-panjang
TRUSTED_HOST_PATTERNS=^localhost$,^127\.0\.0\.1$,^mysite\.com$

# Performance (Set TRUE untuk Production)
CSS_PREPROCESS=FALSE
JS_PREPROCESS=FALSE
ERROR_LEVEL=verbose

# System
UPDATE_FREE_ACCESS=FALSE
```
