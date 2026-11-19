import 'package:url_launcher/url_launcher.dart';

class SupportLauncher {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp _phoneRegex = RegExp(r'^\+?[1-9]\d{6,14}$');
  static final RegExp _whatsappRegex = RegExp(r'^[1-9]\d{6,14}$');

  static bool isHttpsUrl(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    return uri != null &&
        uri.hasScheme &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty;
  }

  static Future<bool> launchEmail(String email, {String? subject}) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || !_emailRegex.hasMatch(trimmed)) return false;

    final queryParams = subject != null
        ? '?subject=${Uri.encodeComponent(subject)}'
        : '';
    final uri = Uri.parse('mailto:$trimmed$queryParams');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> launchPhone(String phone) async {
    final trimmed = phone.trim().replaceAll(RegExp(r'[^\d+]'), '');
    if (trimmed.isEmpty || !_phoneRegex.hasMatch(trimmed)) return false;

    final uri = Uri.parse('tel:$trimmed');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> launchWhatsApp(String phone, {String? text}) async {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty || !_whatsappRegex.hasMatch(digits)) return false;

    final textParam = text != null ? '?text=${Uri.encodeComponent(text)}' : '';
    final uri = Uri.parse('https://wa.me/$digits$textParam');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> launchWebUrl(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return false;

    try {
      final uri = Uri.tryParse(trimmed);
      if (uri == null ||
          !uri.hasScheme ||
          uri.scheme != 'https' ||
          uri.host.isEmpty) {
        return false;
      }
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
