import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../main.dart';

part 'app_localizations.g.dart';

enum AppLanguage { en, ar }

const Map<String, String> defaultEnglishMap = {
  'settings': 'Settings',
  'continue_btn': 'Continue',
  'select_store': 'Select Store',
  'choose_your_store': 'Choose Your Store',
  'search_store': 'Search store',
  'search_store_hint': 'Search store by name...',
  'no_stores_found': 'No stores found',
  'failed_to_load_public_stores': 'Failed to load public stores',
  'not_signed_in_yet': "You're not signed in yet",
  'not_signed_in_desc':
      'Sign in to save favourites, track orders and get picks made for your family.',
  'sign_in': 'SIGN IN',
  'login': 'Login',
  'login_required': 'Login Required',
  'login_required_desc': 'Please login to access your account',
  'login_required_cart_desc':
      'Please login to access your cart items and proceed to checkout',
  'payment_status': 'Payment Status',
  'verified_account': 'Verified',
  'unverified_account': 'Unverified',
  'edit_profile': 'Edit Profile',
  'password': 'Password',
  'log_out': 'Log Out',
  'favorites': 'Favorites',
  'addresses': 'Addresses',
  'notifications': 'Notifications',
  'language': 'Language',
  'app_theme': 'App Theme',
  'dark': 'Dark',
  'light': 'Light',
  'app_version': 'App version',
  'support': 'Support',
  'change_store': 'Change Store',
  'resend_verification_email': 'Resend Verification Email',
  'logout_all_devices': 'Logout All Devices',
  'welcome_back': 'Welcome back',
  'email_address': 'Email Address',
  'forgot_password_q': 'Forgot password?',
  'dont_have_account': "Don't have an account?",
  'sign_up': 'Sign up',
  'retry': 'Retry',
  'failed_to_load_wishlist': 'Failed to load wishlist',
  'failed_to_load_reviews': 'Failed to load reviews',
  'hello_guest': 'Hello, Guest!',
  'in_transit': 'in transit',
  'active_header': 'ACTIVE',
  "newest_first": "Newest first",
  "oldest_first": "Oldest first",
  'track_order': 'Track order',
  'reorder': 'Reorder',
  'arrives': 'Arrives',
  'standard_delivery': 'standard delivery',
  'confirmed_status': 'Confirmed',
  'processing_status': 'Processing',
  'shipped_status': 'Shipped',
  'delivered_status': 'Delivered',
  'failed_to_clear_cart': 'Failed to clear cart',
  'each': 'each',
  'failed_to_remove_item': 'Failed to remove item',
  'you_may_also_like': 'You may also like',
  'delivery_calculated_at_checkout': 'Delivery calculated at checkout',
  'cod_available': 'Cash on delivery available',
  'delivery_added_at_checkout': 'Delivery added at checkout',
  'failed_to_load_cart': 'Failed to load shopping cart',
  'failed_to_load_more': 'Failed to load more',
  'failed_to_load_products_net':
      'Failed to load products. Please check network connection.',
  'failed_to_search_products': 'Failed to search products',
  'edit_review': 'Edit Review',
  'one_size': 'One size',
  'address_label_hint': 'Address Label (e.g. HOME, WORK)',
  'country_code_req': 'Country Code (e.g. KW, SA) *',
  'error_saving_address': 'Error saving address',
  'confirm_delete_address_msg': 'Are you sure you want to delete this address?',
  'select_delivery_address_req': 'Please select a delivery address',
  'failed_to_calc_shipping': 'Failed to calculate shipping options',
  'select_billing_address_req': 'Please select a billing address',
  'select_shipping_method_req': 'Please select a shipping method',
  'wait_preview_complete': 'Please wait for checkout preview to complete.',
  'could_not_launch_payment_url':
      'Could not launch payment gateway URL. Please resume payment from order details.',
  'error_placing_order': 'Error placing order',
  'arrives_tomorrow': 'Arrives tomorrow',
  'arrives_18_20_nov': 'Arrives 18–20 Nov',
  'secure_checkout': 'Secure',
  'email_verification_required': 'Email Verification Required',
  "verification_email_sent": "Verification email sent.",
  'add_address_calc_shipping':
      'Please add a delivery address to calculate shipping.',
  'add_address': 'Add Address',
  'edit_address': 'Edit Address',
  'my_addresses': 'My Addresses',
  'delete_address': 'Delete Address',
  'edit': 'Edit',
  'delete': 'Delete',
  'add_btn': 'Add',
  'apply': 'Apply',
  'change_btn': 'Change',
  'leave_at_reception': 'leave at reception',
  'billing_same_as_shipping': 'Billing address same as shipping',
  'invoice_same_address': 'Invoice goes to the same address',
  'delivery_method': 'Delivery method',
  'uncertain_order_attempt':
      'Previous order attempt outcome uncertain. Please retry placing order first.',
  'calculating_shipping': 'Calculating shipping options...',
  'payment_method': 'Payment',
  'cod_method_label': 'Cash on Delivery (COD)',
  'card_method_label': 'Card Payment',
  'enter_coupon_code_hint': 'Enter coupon code',
  'shipping_label': 'Shipping',
  'tax_label': 'Tax',
  'terms_accept_notice': 'By placing this order you accept the Terms',
  'retry_placing_order': 'Retry Placing Order',
  'invalid_phone_format': 'Invalid phone number format',
  'apt_suite_building_optional': 'Apt, Suite, Building (Optional)',
  'state_region_label': 'State / Region',
  'company_name_optional': 'Company Name (Optional)',
  'set_default_billing_address': 'Set as Default Billing Address',
  'saved_uppercase': 'SAVED',
  'default_first': 'DEFAULT FIRST',
  'default_uppercase': 'DEFAULT',
  'billing_uppercase': 'BILLING',
  'address_tax_notice':
      'Addresses are used for delivery estimates and tax only.',
  'search_country_hint': 'Search country by name or code...',
  'no_countries_found': 'No countries found',
  'failed_to_load_countries':
      'Failed to load countries list. Please try again.',
  'address_label_header': 'Address label',
  'shown_in_your_list': 'Shown in your list',
  'delivery_details_header': 'Delivery details',
  'recipient_header': 'Recipient',
  'required_fields_complete': 'Required fields complete',
  'home_label': 'Home',
  'work_label': 'Work',
  'other_label': 'Other',
  'optional_tag': 'Optional',
  'help_support_title': 'Help & Support',
  'contact_us': 'Contact Us',
  'email_support': 'Email Support',
  'call_us': 'Call Us',
  'whatsapp_support': 'WhatsApp Chat',
  'business_hours': 'Business Hours',
  'faq_title': 'Frequently Asked Questions',
  'store_policies': 'Store Policies',
  'shipping_policy': 'Shipping Policy',
  'return_policy': 'Return & Exchange Policy',
  'privacy_policy': 'Privacy Policy',
  'terms_of_service': 'Terms of Service',
  'no_support_info':
      'No support information is available for this store currently.',
  'could_not_launch_action': 'Could not open link or contact app.',
  'failed_to_load_storefront': 'Failed to load storefront information.',
  'shipping_profile_not_configured':
      'Shipping is not configured for this country',
  'pay_courier_on_delivery': 'Pay the courier when it arrives',
  'paid_online_via_gateway': 'Paid online via gateway',
  'status_subtitle_pending': 'Order pending payment or verification',
  'status_subtitle_confirmed': 'Order received · packed next',
  'status_subtitle_processing': 'Order is being processed',
  'status_subtitle_shipped': 'Order is out for delivery',
  'status_subtitle_delivered': 'Order delivered successfully',
  'status_subtitle_completed': 'Order completed successfully',
  'status_subtitle_cancelled': 'Order cancelled',
  'status_subtitle_in_progress': 'Order in progress',
  'status_subtitle_packing': 'Packing & preparing order',
  'order_cancelled': 'Order cancelled',
  'order_number_hash': 'Order #{number}',
  'qty_label': 'Qty: {quantity}',
  'building_floor_hint': 'Building 116, floor 3',
  'if_required_hint': 'If required',
  'first_name_hint': 'First Name',
  'last_name_hint': 'Last Name',
  'sign_in_to_save_progress': 'Sign in to save your progress',
  'select_address_before_coupon':
      'Please select a delivery address before applying a coupon',
  'no_eligible_fulfillment_warehouse':
      'No shipping option can fulfill this cart for the selected address',
};

const String _languageKey = 'app_language';

@Riverpod(keepAlive: true)
class LanguageNotifier extends _$LanguageNotifier {
  @override
  AppLanguage build() {
    final savedLang = sharedPreferences.getString(_languageKey);
    if (savedLang == 'ar') return AppLanguage.ar;
    if (savedLang == 'en') return AppLanguage.en;
    return AppLanguage.en;
  }

  void setLanguage(AppLanguage lang) {
    state = lang;
    sharedPreferences.setString(
      _languageKey,
      lang == AppLanguage.ar ? 'ar' : 'en',
    );
  }

  void toggleLanguage() {
    final newLang = state == AppLanguage.en ? AppLanguage.ar : AppLanguage.en;
    setLanguage(newLang);
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

class AppLocalizations {
  static AppStrings of(BuildContext context) {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final strings = container.read(appLocalizationLoaderProvider).value ?? {};
      final lang = container.read(languageProvider);
      return AppStrings(strings, lang);
    } catch (_) {
      return AppStrings({}, AppLanguage.en);
    }
  }
}

class AppStrings {
  final Map<String, String> localizedStrings;
  final AppLanguage language;

  AppStrings(this.localizedStrings, this.language);

  bool get isArabic => language == AppLanguage.ar;

  String get(String key) {
    final val = localizedStrings[key];
    if (val != null && val.isNotEmpty) return val;
    if (language == AppLanguage.en) {
      return defaultEnglishMap[key] ?? key;
    }
    return key;
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
  String get noOrdersFound => get('no_orders_found');
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

  String get loginRequired => get('login_required');
  String get loginRequiredCartDesc => get('login_required_cart_desc');
  String get clearCart => get('clear_cart');
  String get cartIsEmpty => get('cart_is_empty');
  String get welcomeBack => get('welcome_back');
  String get emailAddress => get('email_address');
  String get password => get('password');
  String get forgotPasswordQ => get('forgot_password_q');
  String get dontHaveAccount => get('dont_have_account');
  String get signUp => get('sign_up');
  String get resetPassword => get('reset_password');
  String get billing => get('billing');
  String get deleteAddress => get('delete_address');
  String get cancel => get('cancel');
  String get failedToLoadAddresses => get('failed_to_load_addresses');
  String get retry => get('retry');
  String get skip => get('skip');
  String get couponCode => get('coupon_code');
  String get remove => get('remove');
  String get apply => get('apply');
  String get failedToLoadMore => get('failed_to_load_more');
  String get failedToLoadWishlist => get('failed_to_load_wishlist');
  String get failedToLoadNotifications => get('failed_to_load_notifications');
  String get orderDetails => get('order_details');
  String get orderNotFound => get('order_not_found');
  String get paymentStatus => get('payment_status');
  String get resumePayment => get('resume_payment');
  String get openPaymentLink => get('open_payment_link');
  String get verifyPaymentStatus => get('verify_payment_status');
  String get failedToLoadOrderDetails => get('failed_to_load_order_details');
  String get myOrders => get('my_orders');
  String get failedToLoadMoreOrders => get('failed_to_load_more_orders');
  String get failedToLoadOrders => get('failed_to_load_orders');
  String get productReviews => get('product_reviews');
  String get reviewsCount => get('reviews_count');
  String get noReviewsYetForProduct => get('no_reviews_yet_for_product');
  String get failedToLoadMoreReviews => get('failed_to_load_more_reviews');
  String get failedToLoadReviews => get('failed_to_load_reviews');
  String get details => get('details');
  String get reviewTitleOptional => get('review_title_optional');
  String get failedToLoadMoreProducts => get('failed_to_load_more_products');
  String get failedToSearchProducts => get('failed_to_search_products');
  String get passwordsDoNotMatch => get('passwords_do_not_match');
  String get changePassword => get('change_password');
  String get currentPasswordReq => get('current_password_req');
  String get newPasswordReq => get('new_password_req');
  String get confirmNewPasswordReq => get('confirm_new_password_req');
  String get changePasswordBtn => get('change_password_btn');
  String get profileUpdatedSuccess => get('profile_updated_success');
  String get editProfile => get('edit_profile');
  String get firstNameReq => get('first_name_req');
  String get lastNameReq => get('last_name_req');
  String get saveChanges => get('save_changes');
  String get verifiedAccount => get('verified_account');
  String get unverifiedAccount => get('unverified_account');
  String get logOut => get('log_out');
  String get notSignedInYet => get('not_signed_in_yet');
  String get notSignedInDesc => get('not_signed_in_desc');
  String get appTheme => get('app_theme');
  String get dark => get('dark');
  String get light => get('light');
  String get changeStore => get('change_store');
  String get resendVerificationEmail => get('resend_verification_email');
  String get logoutAllDevices => get('logout_all_devices');
  String get selectStore => get('select_store');
  String get chooseYourStore => get('choose_your_store');
  String get searchStore => get('search_store');
  String get searchStoreHint => get('search_store_hint');
  String get noStoresFound => get('no_stores_found');
  String get failedToLoadPublicStores => get('failed_to_load_public_stores');
  String get continueBtn => get('continue_btn');
  String get helloGuest => get('hello_guest');
  String get inTransit => get('in_transit');
  String get activeHeader => get('active_header');
  String get newestFirst => get('newest_first');
  String get oldestFirst => get('oldest_first');
  String get trackOrder => get('track_order');
  String get reorder => get('reorder');
  String get arrives => get('arrives');
  String get standardDelivery => get('standard_delivery');
  String get confirmedStatus => get('confirmed_status');
  String get processingStatus => get('processing_status');
  String get shippedStatus => get('shipped_status');
  String get login => get('login');
  String get deliveredStatus => get('delivered_status');
  String get failedToClearCart => get('failed_to_clear_cart');
  String get each => get('each');
  String get failedToRemoveItem => get('failed_to_remove_item');
  String get youMayAlsoLike => get('you_may_also_like');
  String get deliveryCalculatedAtCheckout =>
      get('delivery_calculated_at_checkout');
  String get codAvailable => get('cod_available');
  String get deliveryAddedAtCheckout => get('delivery_added_at_checkout');
  String get failedToLoadCart => get('failed_to_load_cart');
  String get oneSize => get('one_size');
  String get addressLabelHint => get('address_label_hint');
  String get countryCodeReq => get('country_code_req');
  String get errorSavingAddress => get('error_saving_address');
  String get confirmDeleteAddressMsg => get('confirm_delete_address_msg');
  String get pleaseEnterEmail => get('please_enter_email');
  String get resetInstructionsSent => get('reset_instructions_sent');
  String get failedToProcessRequest => get('failed_to_process_request');
  String get sendInstructions => get('send_instructions');
  String get forgotPasswordDesc => get('forgot_password_desc');
  String get enterEmailAndPassword => get('enter_email_and_password');
  String get loginSuccessful => get('login_successful');
  String get loginFailed => get('login_failed');
  String get loginFailedCheckCredentials =>
      get('login_failed_check_credentials');
  String get pleaseEnterAccountDetails => get('please_enter_account_details');
  String get enterYourPassword => get('enter_your_password');
  String get kidsStudio => get('kids_studio');
  String get learnThroughPlay => get('learn_through_play');
  String get pleaseFillAllFields => get('please_fill_all_fields');
  String get registrationSuccessful => get('registration_successful');
  String get registrationFailed => get('registration_failed');
  String get registrationFailedTryAgain => get('registration_failed_try_again');
  String get nameHint => get('name_hint');
  String get createAPassword => get('create_a_password');
  String get registerHeaderDesc => get('register_header_desc');
  String get selectDeliveryAddressReq => get('select_delivery_address_req');
  String get failedToCalcShipping => get('failed_to_calc_shipping');
  String get selectBillingAddressReq => get('select_billing_address_req');
  String get selectShippingMethodReq => get('select_shipping_method_req');
  String get waitPreviewComplete => get('wait_preview_complete');
  String get couldNotLaunchPaymentUrl => get('could_not_launch_payment_url');
  String get errorPlacingOrder => get('error_placing_order');
  String get arrivesTomorrow => get('arrives_tomorrow');
  String get arrives1820Nov => get('arrives_18_20_nov');
  String get secureCheckout => get('secure_checkout');
  String get emailVerificationRequired => get('email_verification_required');
  String get verificationEmailSent => get('verification_email_sent');
  String get addAddressCalcShipping => get('add_address_calc_shipping');
  String get addBtn => get('add_btn');
  String get changeBtn => get('change_btn');
  String get leaveAtReception => get('leave_at_reception');
  String get billingSameAsShipping => get('billing_same_as_shipping');
  String get invoiceSameAddress => get('invoice_same_address');
  String get deliveryMethod => get('delivery_method');
  String get uncertainOrderAttempt => get('uncertain_order_attempt');
  String get calculatingShipping => get('calculating_shipping');
  String get paymentMethodStr => get('payment_method');
  String get codMethodLabel => get('cod_method_label');
  String get cardMethodLabel => get('card_method_label');
  String get enterCouponCodeHint => get('enter_coupon_code_hint');
  String get shippingLabel => get('shipping_label');
  String get taxLabel => get('tax_label');
  String get termsAcceptNotice => get('terms_accept_notice');
  String get retryPlacingOrder => get('retry_placing_order');
  String get deliverToLabel => get('deliver_to_label');
  String get developmentDeliveryAddress => get('development_delivery_address');
  String get defaultCityCountry => get('default_city_country');
  String get subtotalLabel => get('subtotal_label');
  String get discountLabel => get('discount_label');
  String get getHelp => get('get_help');
  String get orderPlacedStep => get('order_placed_step');
  String get confirmedStep => get('confirmed_step');
  String get estimatedDispatch => get('estimated_dispatch');
  String get trackingLinkHint => get('tracking_link_hint');
  String get estimatedDeliveryRange => get('estimated_delivery_range');
  String get copiedOrderId => get('copied_order_id');
  String get allFilter => get('all_filter');
  String get failedToMarkAllRead => get('failed_to_mark_all_read');
  String get failedToDeleteNotification => get('failed_to_delete_notification');
  String get editReview => get('edit_review');
  String get reviewCommentLabel => get('review_comment_label');
  String get pleaseEnterTitleOrComment => get('please_enter_title_or_comment');
  String get reviewUpdatedSuccess => get('review_updated_success');
  String get saveBtn => get('save_btn');
  String get deleteReviewTitle => get('delete_review_title');
  String get confirmDeleteReview => get('confirm_delete_review');
  String get deleteBtn => get('delete_btn');
  String get reviewDeletedSuccess => get('review_deleted_success');
  String get reviewSubmittedSuccess => get('review_submitted_success');
  String get invalidPhoneFormat => get('invalid_phone_format');
  String get aptSuiteBuildingOptional => get('apt_suite_building_optional');
  String get stateRegionLabel => get('state_region_label');
  String get companyNameOptional => get('company_name_optional');
  String get setDefaultBillingAddress => get('set_default_billing_address');
  String get savedUppercase => get('saved_uppercase');
  String get defaultFirst => get('default_first');
  String get defaultUppercase => get('default_uppercase');
  String get billingUppercase => get('billing_uppercase');
  String get addressTaxNotice => get('address_tax_notice');
  String get searchCountryHint => get('search_country_hint');
  String get noCountriesFound => get('no_countries_found');
  String get failedToLoadCountries => get('failed_to_load_countries');
  String get addressLabelHeader => get('address_label_header');
  String get shownInYourList => get('shown_in_your_list');
  String get deliveryDetailsHeader => get('delivery_details_header');
  String get recipientHeader => get('recipient_header');
  String get requiredFieldsComplete => get('required_fields_complete');
  String get homeLabel => get('home_label');
  String get workLabel => get('work_label');
  String get otherLabel => get('other_label');
  String get optionalTag => get('optional_tag');
  String get reviewOnlyPurchased => get('review_only_purchased');
  String get reviewAlreadySubmitted => get('review_already_submitted');
  String get loginRequiredDesc => get('login_required_desc');
  String get selectRequiredOptions => get('select_required_options');
  String get optionOutOfStock => get('option_out_of_stock');
  String get productUnavailable => get('product_unavailable');
  String get errorAddingToCart => get('error_adding_to_cart');
  String get quantityLabel => get('quantity_label');
  String get defaultProductDescription => get('default_product_description');
  String get noReviewsBeFirst => get('no_reviews_be_first');
  String get failedToLoadProductsNet => get('failed_to_load_products_net');
  String get totalUppercase => get('total_uppercase');
  String get addToCartBtn => get('add_to_cart_btn');
  String get bestsellerLabel => get('bestseller_label');
  String get availableVariantSku => get('available_variant_sku');
  String get outOfStockLabel => get('out_of_stock_label');
  String get categoryLabel => get('category_label');
  String get allCategories => get('all_categories');
  String get brandLabel => get('brand_label');
  String get allBrands => get('all_brands');
  String get sortByLabel => get('sort_by_label');
  String get dateAdded => get('date_added');
  String get priceLabel => get('price_label');
  String get nameLabel => get('name_label');
  String get orderLabel => get('order_label');
  String get descending => get('descending');
  String get ascending => get('ascending');
  String get anyLabel => get('any_label');
  String get passwordComplexityReq => get('password_complexity_req');
  String get newPasswordMustDiffer => get('new_password_must_differ');
  String get passwordChangedSuccess => get('password_changed_success');
  String get failedToChangePassword => get('failed_to_change_password');
  String get failedToUpdateProfile => get('failed_to_update_profile');
  String get loggedOutAllDevicesSuccess =>
      get('logged_out_all_devices_success');
  String get failedToValidateStore => get('failed_to_validate_store');
  String get chooseStoreDesc => get('choose_store_desc');
  String get pendingStatus => get('pending_status');
  String get cancelledStatus => get('cancelled_status');
  String get completedStatus => get('completed_status');
  String get helpSupportTitle => get('help_support_title');
  String get contactUs => get('contact_us');
  String get emailSupport => get('email_support');
  String get callUs => get('call_us');
  String get whatsappSupport => get('whatsapp_support');
  String get businessHours => get('business_hours');
  String get faqTitle => get('faq_title');
  String get storePolicies => get('store_policies');
  String get shippingPolicy => get('shipping_policy');
  String get returnPolicy => get('return_policy');
  String get privacyPolicy => get('privacy_policy');
  String get termsOfService => get('terms_of_service');
  String get noSupportInfo => get('no_support_info');
  String get couldNotLaunchAction => get('could_not_launch_action');
  String get failedToLoadStorefront => get('failed_to_load_storefront');
  String get shippingProfileNotConfigured =>
      get('shipping_profile_not_configured');
  String get payCourierOnDelivery => get('pay_courier_on_delivery');
  String get paidOnlineViaGateway => get('paid_online_via_gateway');
  String get statusSubtitlePending => get('status_subtitle_pending');
  String get statusSubtitleConfirmed => get('status_subtitle_confirmed');
  String get statusSubtitleProcessing => get('status_subtitle_processing');
  String get statusSubtitleShipped => get('status_subtitle_shipped');
  String get statusSubtitleDelivered => get('status_subtitle_delivered');
  String get statusSubtitleCompleted => get('status_subtitle_completed');
  String get statusSubtitleCancelled => get('status_subtitle_cancelled');
  String get statusSubtitleInProgress => get('status_subtitle_in_progress');
  String get statusSubtitlePacking => get('status_subtitle_packing');
  String get orderCancelled => get('order_cancelled');
  String get buildingFloorHint => get('building_floor_hint');
  String get ifRequiredHint => get('if_required_hint');
  String get firstNameHint => get('first_name_hint');
  String get lastNameHint => get('last_name_hint');
  String get signInToSaveProgress => get('sign_in_to_save_progress');
  String get selectAddressBeforeCoupon => get('select_address_before_coupon');
  String get noEligibleFulfillmentWarehouse =>
      get('no_eligible_fulfillment_warehouse');
  String get passwordValidation => get("password_validation");
  String get noAddressesFound => get("no_addresses_found");
  String get shoppingCart => get("shopping_cart");
  String get exitAppTitle => get('exit_app_title');
  String get exitAppDesc => get('exit_app_desc');
  String get continueShopping => get('continue_shopping');
  String get exitAppBtn => get('exit_app_btn');
}
