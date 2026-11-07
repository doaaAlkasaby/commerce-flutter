import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_localizations.g.dart';

enum AppLanguage { en, ar }

@Riverpod(keepAlive: true)
class LanguageNotifier extends _$LanguageNotifier {
  @override
  AppLanguage build() => AppLanguage.en;

  void setLanguage(AppLanguage lang) {
    state = lang;
  }

  void toggleLanguage() {
    state = state == AppLanguage.en ? AppLanguage.ar : AppLanguage.en;
  }
}

@Riverpod(keepAlive: true)
class AppLocalizationLoader extends _$AppLocalizationLoader {
  @override
  Future<Map<String, String>> build() async {
    final lang = ref.watch(languageProvider);
    final fileName = lang == AppLanguage.ar ? 'ar.json' : 'en.json';
    try {
      final jsonString = await rootBundle.loadString('assets/lang/$fileName');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      return {};
    }
  }
}

class AppStrings {
  final Map<String, String> localizedStrings;
  final AppLanguage language;

  AppStrings(this.localizedStrings, this.language);

  bool get isArabic => language == AppLanguage.ar;

  String get(String key) {
    return localizedStrings[key] ?? key;
  }

  String get goodMorning => get('good_morning');
  String get hiAmelia => get('hi_amelia');
  String get searchHint => get('search_hint');
  String get categories => get('categories');
  String get seeAll => get('see_all');
  String get summerSale => get('summer_sale');
  String get saleDesc => get('sale_desc');
  String get shopNow => get('shop_now');
  String get popularForLittleOnes => get('popular_for_little_ones');
  String get home => get('home');
  String get shop => get('shop');
  String get cart => get('cart');
  String get saved => get('saved');
  String get profile => get('profile');
  String get orders => get('orders');
  String get settings => get('settings');
  String get favorites => get('favorites');
  String get addresses => get('addresses');
  String get notifications => get('notifications');
  String get support => get('support');
  String get storeLocator => get('store_locator');
  String get newsletter => get('newsletter');
  String get languageStr => get('language');
  String get appVersion => get('app_version');
  String get signIn => get('sign_in');
  String get createAccount => get('create_account');
  String get checkout => get('checkout');
  String get deliveryAddress => get('delivery_address');
  String get billingAddress => get('billing_address');
  String get yourOrder => get('your_order');
  String get orderNote => get('order_note');
  String get discountCode => get('discount_code');
  String get priceSummary => get('price_summary');
  String get placeOrder => get('place_order');
  String get total => get('total');
  String get addToCart => get('add_to_cart');
  String get addedToCart => get('added_to_cart');
  String get updateRequired => get('update_required');
  String get updateMessage => get('update_message');
  String get currentBuildStr => get('current_build');
  String get supportedBuildsStr => get('supported_builds');
  String get later => get('later');
  String get updateNow => get('update_now');
  String get switchLanguage => get('switch_language');
  String get toggleTheme => get('toggle_theme');
  String get exploreCollections => get('explore_collections');
  String get newSeason => get('new_season');
  String get organicPlay => get('organic_play');
  String get collections => get('collections');
  String get items => get('items');
  String get toysLabel => get('toys_label');
  String get inStock => get('in_stock');
  String get freeDelivery => get('free_delivery');
  String get colour => get('colour');
  String get size => get('size');
  String get sizeGuide => get('size_guide');
  String get addGiftWrap => get('add_gift_wrap');
  String get giftWrapDesc => get('gift_wrap_desc');
  String get onlyLeft => get('only_left');
  String get description => get('description');
  String get readMore => get('read_more');
  String get writeReview => get('write_review');
  String get yourRating => get('your_rating');
  String get tellParents => get('tell_parents');
  String get addPhoto => get('add_photo');
  String get postReview => get('post_review');
  String get seeAllReviews => get('see_all_reviews');
  String get reviewsHeader => get('reviews_header');
  String get filterProducts => get('filter_products');
  String get reset => get('reset');
  String get priceRange => get('price_range');
  String get minimumRating => get('minimum_rating');
  String get applyFilters => get('apply_filters');
  String get searchProductsHint => get('search_products_hint');
  String get noProductsFound => get('no_products_found');
  String get tryAdjusting => get('try_adjusting');
  String get all => get('all');
  String get myAddresses => get('my_addresses');
  String get defaultLabel => get('default_label');
  String get setAsDefault => get('set_as_default');
  String get edit => get('edit');
  String get delete => get('delete');
  String get addAddress => get('add_address');
  String get editAddress => get('edit_address');
  String get saveAddress => get('save_address');
  String get updateAddress => get('update_address');
  String get fullName => get('full_name');
  String get streetAddress => get('street_address');
  String get city => get('city');
  String get postalCode => get('postal_code');
  String get phoneNumber => get('phone_number');
  String get setDefaultAddress => get('set_default_address');
  String get fillRequired => get('fill_required');
  String get noFavoritesYet => get('no_favorites_yet');
  String get tapTheHeart => get('tap_the_heart');
  String get browseTheShop => get('browse_the_shop');
  String get removedFromFavorites => get('removed_from_favorites');
  String get undo => get('undo');
  String get syncDevices => get('sync_devices');
  String get markAllRead => get('mark_all_read');
  String get noNotifications => get('no_notifications');
  String get noNotificationsDesc => get('no_notifications_desc');
}
