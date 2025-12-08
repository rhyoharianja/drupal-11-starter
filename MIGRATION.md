# Panduan Migrasi & Upgrade ke Drupal 11

Dokumen ini menjelaskan langkah-langkah untuk melakukan upgrade dari versi Drupal sebelumnya (8, 9, 10) ke Drupal 11, serta cara memigrasikan situs yang sudah ada ke environment Docker ini.

## ⚠️ Peringatan Penting
- **Backup Selalu!**: Sebelum melakukan operasi apapun, pastikan Anda memiliki backup lengkap (Database & Files).
- **Environment**: Pastikan environment lokal Anda sudah memenuhi syarat Drupal 11 (PHP 8.3+, PostgreSQL 16+ / MySQL 8+). Template Docker ini sudah memenuhi syarat tersebut.

---

## 🔄 Alur Upgrade (Upgrade Path)

Drupal tidak mendukung loncatan versi mayor secara langsung (misal: 8 ke 11). Anda harus melakukan upgrade secara bertahap.

### 1. Drupal 8 ke Drupal 9
Drupal 8 sudah mencapai End-of-Life (EOL).
1.  Update core Drupal 8 ke versi terakhir (8.9.x).
2.  Update semua modul contrib ke versi yang kompatibel dengan Drupal 8 dan 9.
3.  Perbaiki kode kustom yang menggunakan API usang (deprecated).
4.  Jalankan update ke Drupal 9 via Composer.

### 2. Drupal 9 ke Drupal 10
1.  Pastikan Anda berada di Drupal 9 versi terakhir (9.5.x).
2.  Pastikan PHP versi 8.1 atau lebih baru.
3.  Gunakan **Upgrade Status** module untuk mengecek kesiapan modul dan tema.
4.  Update `composer.json` untuk require Drupal 10.
5.  Jalankan `composer update`.
6.  Jalankan database update (`drush updb`).

### 3. Drupal 10 ke Drupal 11
Ini adalah target akhir kita.
1.  Pastikan Anda berada di Drupal 10.3+ atau 10.4+.
2.  Pastikan PHP versi 8.3 (Template ini menggunakan PHP 8.4).
3.  Cek kompatibilitas modul dengan **Upgrade Status**.
4.  Hapus modul yang sudah masuk ke core atau tidak lagi didukung.

---

## 🚀 Langkah Upgrade ke Drupal 11 (Detail)

Asumsi: Anda sudah berada di Drupal 10.3+ dan ingin upgrade ke Drupal 11 menggunakan template ini.

### Langkah 1: Persiapan Kode
1.  Buka `composer.json` di root proyek Anda.
2.  Ubah requirement core:
    ```json
    "require": {
        "drupal/core-composer-scaffold": "^11.0",
        "drupal/core-project-message": "^11.0",
        "drupal/core-recommended": "^11.0",
        "drush/drush": "^13.0"
    }
    ```
3.  Hapus dependensi yang mungkin konflik atau tidak kompatibel.

### Langkah 2: Update Dependensi
Jalankan perintah berikut di terminal (atau di dalam container):
```bash
composer update "drupal/core-*" --with-all-dependencies
```

### Langkah 3: Update Database
Setelah kode terupdate, jalankan update database:
```bash
drush updb -y
drush cache:rebuild
```

---

## 📦 Migrasi ke Docker Template Ini

Jika Anda memiliki situs Drupal (8/9/10/11) di server lain dan ingin memindahkannya ke template Docker ini:

### 1. Siapkan File & Database
1.  **Database**: Export database lama Anda ke file SQL (misal: `backup.sql`).
2.  **Files**: Salin folder `sites/default/files` dari server lama.
3.  **Code**: Jika ada modul/tema kustom, salin ke `web/modules/custom` dan `web/themes/custom`.

### 2. Import ke Docker
1.  Jalankan container: `docker compose up -d`.
2.  **Import Database**:
    ```bash
    # Salin file sql ke dalam container (atau folder root)
    cat backup.sql | docker compose exec -T postgres psql -U admin -d aleph-drupal
    ```
    *(Sesuaikan user, db name, dan password sesuai .env)*

3.  **Salin Files**:
    Letakkan folder `files` Anda ke `web/sites/default/files` di folder proyek ini.

4.  **Sesuaikan `settings.php`**:
    Template ini menggunakan `settings.php` yang dinamis. Pastikan `hash_salt` di `.env` sama dengan situs lama Anda jika ingin session user tetap valid (opsional).

5.  **Clear Cache**:
    ```bash
    docker compose exec php vendor/bin/drush cr
    ```

### 3. Troubleshooting Migrasi
- **Error Koneksi DB**: Cek `.env` pastikan kredensial sesuai.
- **White Screen (WSOD)**: Cek log dengan `docker compose logs -f php`. Biasanya karena modul yang kurang atau versi PHP yang tidak cocok.
- **Permission**: Jalankan `chown -R www-data:www-data web/sites/default/files` di dalam container jika ada masalah upload gambar.
