class CountryHelper {
  static String getCountryFlag(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'KW':
      case 'KWT':
        return '🇰🇼';
      case 'SA':
      case 'SAU':
      case 'KSA':
        return '🇸🇦';
      case 'AE':
      case 'ARE':
      case 'UAE':
        return '🇦🇪';
      case 'EG':
      case 'EGY':
        return '🇪🇬';
      case 'QA':
      case 'QAR':
        return '🇶🇦';
      case 'BH':
      case 'BHD':
        return '🇧🇭';
      case 'OM':
      case 'OMR':
        return '🇴🇲';
      default:
        return '🌐';
    }
  }

  static String getCountryDisplayName(String countryCode, bool isArabic) {
    switch (countryCode.toUpperCase()) {
      case 'KW':
      case 'KWT':
        return isArabic ? 'الكويت' : 'Kuwait';
      case 'SA':
      case 'SAU':
      case 'KSA':
        return isArabic ? 'السعودية' : 'Saudi Arabia';
      case 'AE':
      case 'ARE':
      case 'UAE':
        return isArabic ? 'الإمارات' : 'UAE';
      case 'EG':
      case 'EGY':
        return isArabic ? 'مصر' : 'Egypt';
      case 'QA':
      case 'QAR':
        return isArabic ? 'قطر' : 'Qatar';
      case 'BH':
      case 'BHD':
        return isArabic ? 'البحرين' : 'Bahrain';
      case 'OM':
      case 'OMR':
        return isArabic ? 'عمان' : 'Oman';
      default:
        return countryCode.toUpperCase();
    }
  }
}
