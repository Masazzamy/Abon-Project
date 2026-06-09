import 'package:intl/intl.dart';

class WaktuHelper {
  // Format: EEEE, dd MMMM yyyy (Indonesian)
  static String getTanggalLengkap() {
    final now = DateTime.now();
    try {
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);
    } catch (_) {
      // Fallback if localizations aren't loaded or throw an error
      return DateFormat('EEEE, dd MMMM yyyy').format(now);
    }
  }

  // Dynamic greetings based on system hour
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) {
      return 'Selamat Pagi ☀️';
    }
    if (hour >= 12 && hour < 15) {
      return 'Selamat Siang 🌤️';
    }
    if (hour >= 15 && hour < 18) {
      return 'Selamat Sore 🌅';
    }
    return 'Selamat Malam 🌙';
  }

  // Format: HH:mm
  static String getJamSekarang() {
    return DateFormat('HH:mm').format(DateTime.now());
  }

  // Dynamic zone detection
  static String getZonaWaktu() {
    final offset = DateTime.now().timeZoneOffset.inHours;
    if (offset == 7) return 'WIB';
    if (offset == 8) return 'WITA';
    if (offset == 9) return 'WIT';
    return 'WIB'; // Default to WIB
  }

  // Format relative time: timeago (Indonesian fallback)
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      try {
        return DateFormat('dd MMM yyyy', 'id_ID').format(dateTime);
      } catch (_) {
        return DateFormat('dd MMM yyyy').format(dateTime);
      }
    }
  }
}
