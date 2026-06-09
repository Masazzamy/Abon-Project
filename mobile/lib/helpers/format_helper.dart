import 'package:intl/intl.dart';

class FormatHelper {
  // Format numeric values into Indonesian Rupiah (Rp)
  static String formatRupiah(dynamic amount) {
    if (amount == null) return 'Rp 0';
    
    num number;
    if (amount is String) {
      number = num.tryParse(amount) ?? 0;
    } else if (amount is num) {
      number = amount;
    } else {
      return 'Rp 0';
    }

    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(number);
  }
}
