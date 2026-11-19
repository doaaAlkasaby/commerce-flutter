import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentUrlLauncher {
  static String normalizeUrl(String rawUrl) {
    if (rawUrl.trim().isEmpty) return '';
    try {
      final uri = Uri.parse(rawUrl.trim());
      if (defaultTargetPlatform == TargetPlatform.android &&
          (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
        return uri.replace(host: '10.0.2.2').toString();
      }
      return uri.toString();
    } catch (_) {
      return rawUrl;
    }
  }

  static Future<bool> launchPaymentUrl(String rawUrl) async {
    if (rawUrl.trim().isEmpty) return false;
    try {
      final normalized = normalizeUrl(rawUrl);
      final uri = Uri.parse(normalized);
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return false;
      }
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
