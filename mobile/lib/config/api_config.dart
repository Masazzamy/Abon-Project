import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String localIp = '10.175.124.237'; // AUTOMATICALLY UPDATED BY STARTUP SCRIPT
  static const String port = '8000';
  
  static String get defaultBaseUrl {
    if (kIsWeb) {
      final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
      return 'http://$host:$port/api';
    }
    return 'http://$localIp:$port/api';
  }
}
