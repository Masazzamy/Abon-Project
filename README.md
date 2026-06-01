# 🚀 Abon Salakopi - Launcher & Panduan Koneksi Development

Dokumentasi ini berisi panduan lengkap cara menjalankan backend Laravel, database MySQL, dan aplikasi Flutter secara otomatis serta panduan pengetesan menggunakan HP Android fisik melalui jaringan lokal (Wi-Fi).

---

## 🛠️ Cara Menjalankan Project (Sekali Klik)

Kami telah membuat script launcher otomatis `start_project.bat` di folder root project. Untuk menjalankannya:

1. Pastikan **XAMPP Control Panel** terinstal di PC/Laptop Anda di direktori default (`C:\xampp`).
2. Sambungkan **HP Android** Anda ke PC/Laptop dengan kabel USB (baca bagian pengetesan di bawah).
3. **Double-click** file **`start_project.bat`** di folder root project ini.
4. **Apa yang dilakukan script ini secara otomatis?**
   - Mendeteksi IP Wi-Fi/Local LAN laptop Anda secara dinamis.
   - Menulis IP tersebut ke file konfigurasi Flutter (`mobile/lib/config/api_config.dart`).
   - Memulai service database **MySQL XAMPP** (jika belum berjalan di port 3306).
   - Membuka window baru untuk menjalankan server API **Laravel** (`php artisan serve --host=0.0.0.0 --port=8000`).
   - Menjalankan perintah **`flutter run`** di terminal utama untuk mengompilasi dan mengunduh aplikasi ke HP Android Anda.

---

## 📱 Cara Testing di HP Android Fisik

Agar aplikasi Flutter di HP Android Anda bisa berkomunikasi dengan database & backend Laravel di laptop, ikuti langkah berikut:

### 1. Aktifkan USB Debugging di HP
- Masuk ke **Pengaturan HP** -> **Tentang Ponsel** (About Phone).
- Ketuk **Nomor Versi** (Build Number) sebanyak 7 kali hingga muncul pesan "Anda sekarang adalah seorang pengembang".
- Kembali ke menu utama Pengaturan, cari **Opsi Pengembang** (Developer Options).
- Aktifkan **Opsi Pengembang** dan centang **Debugging USB** (USB Debugging).

### 2. Hubungkan ke Jaringan Wi-Fi yang Sama
- Hubungkan Laptop/PC Anda dan HP Android ke **satu jaringan Wi-Fi yang sama** (misal: Wi-Fi rumah atau Hotspot HP Anda).
- *Catatan:* Wi-Fi publik (seperti kafe atau kampus) seringkali mengisolasi perangkat (AP Isolation), sehingga HP dan laptop tidak bisa saling berkomunikasi. **Disarankan menggunakan Hotspot Pribadi dari HP**.

### 3. Sambungkan HP ke Laptop
- Hubungkan HP ke laptop menggunakan kabel USB.
- Jika muncul pop-up konfirmasi di layar HP untuk "Izinkan Debugging USB", pilih **Izinkan** (Allow).

---

## 🔍 Cara Mencari IP Local Laptop (Manual)

Script `start_project.bat` akan mendeteksi IP Anda secara otomatis. Namun, jika Anda ingin memeriksanya secara manual:

1. Buka **Command Prompt (CMD)** di Windows.
2. Ketik perintah: `ipconfig` lalu tekan **Enter**.
3. Cari adaptor jaringan Anda yang sedang aktif, biasanya bernama:
   - `Wireless LAN adapter Wi-Fi` (jika menggunakan Wi-Fi).
   - `Ethernet adapter` (jika menggunakan kabel LAN).
4. Cari baris **IPv4 Address**. Formatnya akan seperti: `192.168.x.x` atau `10.x.x.x`. Ini adalah IP local laptop Anda.

---

## 🛑 Cara Mengatasi Koneksi Gagal (Troubleshooting)

Jika Anda menekan tombol **"TEST KONEKSI SERVER"** di aplikasi Flutter dan muncul pesan **Koneksi Gagal**, ikuti langkah perbaikan ini:

### 1. Masalah Isolasi Jaringan (Paling Sering Terjadi)
- **Gejala:** Server Laravel sudah jalan, tapi HP tidak bisa nge-ping IP laptop.
- **Solusi:** Matikan Wi-Fi rumah/publik. Aktifkan **Hotspot Pribadi (Tethering)** di HP Android Anda, lalu sambungkan Laptop ke Hotspot HP tersebut. Jalankan kembali `start_project.bat`.

### 2. Terblokir Windows Defender / Firewall
- **Gejala:** Koneksi ditolak oleh Windows.
- **Solusi:** Windows Firewall terkadang memblokir lalu lintas port `8000`.
  1. Buka Windows Search, ketik **Windows Defender Firewall with Advanced Security**.
  2. Pilih **Inbound Rules** di panel kiri, lalu klik **New Rule...** di panel kanan.
  3. Pilih **Port**, klik Next.
  4. Pilih **TCP**, masukkan port `8000` di bagian *Specific local ports*, klik Next.
  5. Pilih **Allow the connection**, klik Next hingga selesai, dan beri nama "Laravel API Port 8000".

### 3. Port Konflik (Port 8000 atau 3306 Sibuk)
- **Gejala:** Server Laravel gagal berjalan karena port 8000 sudah dipakai proses lain.
- **Solusi:** Script `start_project.bat` secara otomatis mendeteksi dan menghentikan proses yang mengunci port 8000 sebelum menyalakan server baru. Jika MySQL bentrok, pastikan tidak ada aplikasi database lain (seperti MySQL standalone atau PostgreSQL) yang memakai port 3306.

---

## 📂 Struktur Folder API Clean

Aplikasi mobile kini menggunakan struktur arsitektur bersih untuk interaksi jaringan:
```
mobile/lib/
├── api/
│   └── api_client.dart       # HTTP client utama dengan auto-timeout & error handling global
├── config/
│   └── api_config.dart      # Konfigurasi IP & Base URL (diperbarui otomatis oleh .bat)
├── models/
│   ├── notification_model.dart
│   ├── product_model.dart    # Model data produk
│   └── user_model.dart
└── services/
    ├── auth_service.dart     # Service autentikasi (login, register, logout, ping)
    ├── notification_service.dart
    └── product_service.dart  # Service manajemen produk (GET products)
```