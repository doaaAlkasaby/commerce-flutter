class FAQItemModel {
  final String question;
  final String answer;

  const FAQItemModel({required this.question, required this.answer});

  factory FAQItemModel.fromJson(Map<String, dynamic> json) {
    return FAQItemModel(
      question: json['question']?.toString() ?? json['q']?.toString() ?? '',
      answer: json['answer']?.toString() ?? json['a']?.toString() ?? '',
    );
  }
}

class HelpSupportModel {
  final String? email;
  final String? phone;
  final String? whatsapp;
  final String? businessHours;
  final String? shippingPolicy;
  final String? returnPolicy;
  final String? privacyPolicyUrl;
  final String? termsUrl;
  final List<FAQItemModel> faqs;

  bool get hasContactInfo =>
      (email != null && email!.isNotEmpty) ||
      (phone != null && phone!.isNotEmpty) ||
      (whatsapp != null && whatsapp!.isNotEmpty) ||
      (businessHours != null && businessHours!.isNotEmpty);

  bool get hasPolicies =>
      (shippingPolicy != null && shippingPolicy!.isNotEmpty) ||
      (returnPolicy != null && returnPolicy!.isNotEmpty) ||
      (privacyPolicyUrl != null && privacyPolicyUrl!.isNotEmpty) ||
      (termsUrl != null && termsUrl!.isNotEmpty);

  bool get hasFaqs => faqs.isNotEmpty;

  bool get isEmpty => !hasContactInfo && !hasPolicies && !hasFaqs;

  const HelpSupportModel({
    this.email,
    this.phone,
    this.whatsapp,
    this.businessHours,
    this.shippingPolicy,
    this.returnPolicy,
    this.privacyPolicyUrl,
    this.termsUrl,
    this.faqs = const [],
  });

  factory HelpSupportModel.fromSettingsData(dynamic rawData) {
    String? email;
    String? phone;
    String? whatsapp;
    String? businessHours;
    String? shippingPolicy;
    String? returnPolicy;
    String? privacyPolicyUrl;
    String? termsUrl;
    List<FAQItemModel> faqs = [];

    Map<String, dynamic> settingsMap = {};

    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map<String, dynamic> && item['key'] != null) {
          settingsMap[item['key'].toString()] = item['value'];
        }
      }
    } else if (rawData is Map<String, dynamic>) {
      settingsMap = rawData;
    }

    email =
        settingsMap['support_email']?.toString() ??
        settingsMap['email']?.toString();
    phone =
        settingsMap['support_phone']?.toString() ??
        settingsMap['phone']?.toString();
    whatsapp =
        settingsMap['whatsapp']?.toString() ??
        settingsMap['whatsapp_number']?.toString();
    businessHours = settingsMap['business_hours']?.toString();
    shippingPolicy = settingsMap['shipping_policy']?.toString();
    returnPolicy = settingsMap['return_policy']?.toString();
    privacyPolicyUrl = settingsMap['privacy_policy_url']?.toString();
    termsUrl = settingsMap['terms_url']?.toString();

    final rawFaqs = settingsMap['faq'] ?? settingsMap['faqs'];
    if (rawFaqs is List) {
      faqs = rawFaqs
          .whereType<Map<String, dynamic>>()
          .map((json) => FAQItemModel.fromJson(json))
          .where((item) => item.question.isNotEmpty && item.answer.isNotEmpty)
          .toList();
    }

    return HelpSupportModel(
      email: email?.trim(),
      phone: phone?.trim(),
      whatsapp: whatsapp?.trim(),
      businessHours: businessHours?.trim(),
      shippingPolicy: shippingPolicy?.trim(),
      returnPolicy: returnPolicy?.trim(),
      privacyPolicyUrl: privacyPolicyUrl?.trim(),
      termsUrl: termsUrl?.trim(),
      faqs: faqs,
    );
  }
}
