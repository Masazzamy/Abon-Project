@echo off
title Abon Salakopi - Launcher Otomatis
color 0E
cls

echo ===================================================
echo   LAUNCHER OTOMATIS: ABON SALAKOPI DEVELOPMENT
echo ===================================================
echo.

:: 1. Deteksi IP Local (Wi-Fi Utama / Local Network)
echo [1/5] Mendeteksi IP Address laptop Anda...
for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like '*Wi-Fi*' -and $_.IPAddress -notlike '169.254.*' } | Select-Object -First 1).IPAddress; if (-not $ip) { $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.0.0.1' -and $_.IPAddress -notlike '169.254.*' } | Select-Object -First 1).IPAddress }; $ip"`) do set LOCAL_IP=%%i

if "%LOCAL_IP%"=="" (
    echo [WARNING] IP local tidak terdeteksi! Menggunakan fallback '127.0.0.1'.
    set LOCAL_IP=127.0.0.1
) else (
    echo [SUCCESS] IP Address Terdeteksi: %LOCAL_IP%
)
echo.

:: 2. Update Config API Flutter
echo [2/5] Memperbarui konfigurasi API Flutter...
powershell -NoProfile -Command "(Get-Content -Path 'mobile/lib/config/api_config.dart') -replace 'static const String localIp = \'.*?\';', 'static const String localIp = ''%LOCAL_IP%'';' | Set-Content -Path 'mobile/lib/config/api_config.dart'"
if %errorlevel% equ 0 (
    echo [SUCCESS] File 'mobile/lib/config/api_config.dart' berhasil di-update.
) else (
    echo [ERROR] Gagal memperbarui config file. Pastikan struktur project sudah benar.
)
echo.

:: 3. Jalankan Database MySQL XAMPP
echo [3/5] Memeriksa koneksi database MySQL (Port 3306)...
netstat -ano | findstr :3306 >nul
if %errorlevel% neq 0 (
    echo [DATABASE] MySQL tidak aktif. Menjalankan MySQL XAMPP...
    if exist "C:\xampp\mysql_start.bat" (
        start "XAMPP MySQL Server" /min "C:\xampp\mysql_start.bat"
        echo [DATABASE] Mengaktifkan MySQL server...
        timeout /t 5 >nul
    ) else (
        echo [ERROR] File 'C:\xampp\mysql_start.bat' tidak ditemukan.
        echo [ERROR] Silakan jalankan MySQL dari XAMPP Control Panel secara manual!
        pause
    )
) else (
    echo [SUCCESS] MySQL XAMPP sudah berjalan secara aktif di port 3306.
)
echo.

:: 4. Jalankan Laravel Backend
echo [4/5] Menjalankan Laravel API Server di %LOCAL_IP%:8000...
:: Tutup server lama jika ada di port 8000
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8000') do taskkill /F /PID %%a 2>nul
start "Laravel API Server" cmd /c "cd backend && php artisan serve --host=0.0.0.0 --port=8000"
timeout /t 3 >nul
echo [SUCCESS] Laravel API Server berjalan di background (Window terpisah).
echo.

:: 5. Jalankan Aplikasi Flutter
echo [5/5] Memulai aplikasi Flutter...
echo.
echo ===================================================
echo     PETUNJUK TESTING DENGAN HP ANDROID ASLI
echo ===================================================
echo  1. Sambungkan HP Android laptop Anda lewat kabel USB.
echo  2. Pastikan USB Debugging di HP Android sudah AKTIF.
echo  3. Pastikan HP dan laptop terhubung ke Wi-Fi yang SAMA.
echo  4. IP Laptop Anda: %LOCAL_IP%
echo  5. Aplikasi Flutter akan dijalankan sekarang...
echo ===================================================
echo.

cd mobile
flutter run

pause
