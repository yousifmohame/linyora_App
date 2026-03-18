import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Linyora'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navCategories;

  /// No description provided for @navReels.
  ///
  /// In en, this message translates to:
  /// **'Reels'**
  String get navReels;

  /// No description provided for @navtrends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get navtrends;

  /// No description provided for @navProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get navProfile;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @guestTitle.
  ///
  /// In en, this message translates to:
  /// **'Login to enjoy full shopping experience'**
  String get guestTitle;

  /// No description provided for @loginSignup.
  ///
  /// In en, this message translates to:
  /// **'Login / Sign Up'**
  String get loginSignup;

  /// No description provided for @ordersAndPurchases.
  ///
  /// In en, this message translates to:
  /// **'Orders & Purchases'**
  String get ordersAndPurchases;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'My Points'**
  String get points;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @trends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get trends;

  /// No description provided for @accountAndWallet.
  ///
  /// In en, this message translates to:
  /// **'Account & Wallet'**
  String get accountAndWallet;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @myAddresses.
  ///
  /// In en, this message translates to:
  /// **'My Addresses'**
  String get myAddresses;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language / اللغة'**
  String get language;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About Linyora'**
  String get aboutApp;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @statsOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get statsOrders;

  /// No description provided for @statsFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get statsFollowers;

  /// No description provided for @statsVouchers.
  ///
  /// In en, this message translates to:
  /// **'Vouchers'**
  String get statsVouchers;

  /// No description provided for @userGuest.
  ///
  /// In en, this message translates to:
  /// **'Linyora User'**
  String get userGuest;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @profileUpdatedSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessMsg;

  /// No description provided for @profileUpdateFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Update failed, please try again'**
  String get profileUpdateFailedMsg;

  /// No description provided for @fullNameInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameInputLabel;

  /// No description provided for @pleaseEnterNameMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterNameMsg;

  /// No description provided for @phoneNumberInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberInputLabel;

  /// No description provided for @saveChangesBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesBtn;

  /// No description provided for @layoutSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Home page layout saved successfully!'**
  String get layoutSavedSuccess;

  /// No description provided for @layoutSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: '**
  String get layoutSaveFailed;

  /// No description provided for @shopByCategory.
  ///
  /// In en, this message translates to:
  /// **'Shop by Category'**
  String get shopByCategory;

  /// No description provided for @newArrivals.
  ///
  /// In en, this message translates to:
  /// **'New Arrivals'**
  String get newArrivals;

  /// No description provided for @linyoraPicks.
  ///
  /// In en, this message translates to:
  /// **'Linyora Picks'**
  String get linyoraPicks;

  /// No description provided for @seasonStyle.
  ///
  /// In en, this message translates to:
  /// **'Season Style'**
  String get seasonStyle;

  /// No description provided for @bestSellers.
  ///
  /// In en, this message translates to:
  /// **'Best Sellers'**
  String get bestSellers;

  /// No description provided for @topRated.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get topRated;

  /// No description provided for @topModelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Models'**
  String get topModelsTitle;

  /// No description provided for @topMerchantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Merchants'**
  String get topMerchantsTitle;

  /// No description provided for @labelMarquee.
  ///
  /// In en, this message translates to:
  /// **'News Ticker'**
  String get labelMarquee;

  /// No description provided for @labelStories.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get labelStories;

  /// No description provided for @labelBanners.
  ///
  /// In en, this message translates to:
  /// **'Ad Banners'**
  String get labelBanners;

  /// No description provided for @labelFlashSale.
  ///
  /// In en, this message translates to:
  /// **'Flash Sale'**
  String get labelFlashSale;

  /// No description provided for @labelCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get labelCategories;

  /// No description provided for @labelDynamicSection.
  ///
  /// In en, this message translates to:
  /// **'Special Section: '**
  String get labelDynamicSection;

  /// No description provided for @saveLayout.
  ///
  /// In en, this message translates to:
  /// **'Save Layout'**
  String get saveLayout;

  /// No description provided for @editLayout.
  ///
  /// In en, this message translates to:
  /// **'Edit Layout'**
  String get editLayout;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'What are you looking for today?'**
  String get searchHint;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications currently'**
  String get noNotifications;

  /// No description provided for @notificationsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update notifications'**
  String get notificationsFailed;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'Linyora is not just an app, it\'s a community!'**
  String get aboutTitle;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'We combine the joy of watching short videos with the ease of online shopping. Discover the latest trends, follow your favorite influencers, and order the products you love with a click.'**
  String get aboutDescription;

  /// No description provided for @visitWebsite.
  ///
  /// In en, this message translates to:
  /// **'Visit our website'**
  String get visitWebsite;

  /// No description provided for @returnPolicy.
  ///
  /// In en, this message translates to:
  /// **'Return Policy'**
  String get returnPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @followUs.
  ///
  /// In en, this message translates to:
  /// **'Follow us on'**
  String get followUs;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2024 Linyora Inc. All rights reserved.'**
  String get copyright;

  /// No description provided for @contactSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Your message has been sent successfully!'**
  String get contactSuccessMsg;

  /// No description provided for @contactErrorMsg.
  ///
  /// In en, this message translates to:
  /// **'Failed to send: Please try again later'**
  String get contactErrorMsg;

  /// No description provided for @contactUsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUsTitle;

  /// No description provided for @contactWelcome.
  ///
  /// In en, this message translates to:
  /// **'We are here to help 👋'**
  String get contactWelcome;

  /// No description provided for @contactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Have a question or inquiry? Contact us via the form below or our direct channels.'**
  String get contactSubtitle;

  /// No description provided for @customerService.
  ///
  /// In en, this message translates to:
  /// **'Customer Service'**
  String get customerService;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @headquarters.
  ///
  /// In en, this message translates to:
  /// **'Headquarters'**
  String get headquarters;

  /// No description provided for @hqAddress.
  ///
  /// In en, this message translates to:
  /// **'Riyadh, Saudi Arabia'**
  String get hqAddress;

  /// No description provided for @sendMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Send us a message'**
  String get sendMessageTitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @messageBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageBodyLabel;

  /// No description provided for @messageRequired.
  ///
  /// In en, this message translates to:
  /// **'Message is required'**
  String get messageRequired;

  /// No description provided for @sendBtn.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendBtn;

  /// No description provided for @followUsOnSocialMedia.
  ///
  /// In en, this message translates to:
  /// **'Follow us on social media'**
  String get followUsOnSocialMedia;

  /// No description provided for @sectionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Section is currently unavailable'**
  String get sectionUnavailable;

  /// No description provided for @noProductsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No products available'**
  String get noProductsAvailable;

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping Cart'**
  String get cartTitle;

  /// No description provided for @emptyCartDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty Cart'**
  String get emptyCartDialogTitle;

  /// No description provided for @emptyCartDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all products?'**
  String get emptyCartDialogContent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cartEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your cart is currently empty'**
  String get cartEmptyMessage;

  /// No description provided for @startShoppingBtn.
  ///
  /// In en, this message translates to:
  /// **'Start Shopping'**
  String get startShoppingBtn;

  /// No description provided for @productRemovedFromCart.
  ///
  /// In en, this message translates to:
  /// **'Product removed from cart'**
  String get productRemovedFromCart;

  /// No description provided for @productDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product deleted'**
  String get productDeleted;

  /// No description provided for @specifications.
  ///
  /// In en, this message translates to:
  /// **'Specifications: '**
  String get specifications;

  /// No description provided for @currencySAR.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get currencySAR;

  /// No description provided for @maxQuantityReached.
  ///
  /// In en, this message translates to:
  /// **'Sorry, this is the maximum available quantity'**
  String get maxQuantityReached;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @checkoutBtn.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutBtn;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @dataLoadError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading data'**
  String get dataLoadError;

  /// No description provided for @selectShippingAddressMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select a shipping address'**
  String get selectShippingAddressMsg;

  /// No description provided for @selectShippingMethodMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select a shipping method for each merchant'**
  String get selectShippingMethodMsg;

  /// No description provided for @selectPaymentCardMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment card'**
  String get selectPaymentCardMsg;

  /// No description provided for @orderSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Order placed successfully!'**
  String get orderSuccessMsg;

  /// No description provided for @errorOccurredMsg.
  ///
  /// In en, this message translates to:
  /// **'Error: '**
  String get errorOccurredMsg;

  /// No description provided for @loginToCompleteOrder.
  ///
  /// In en, this message translates to:
  /// **'Login to complete the order'**
  String get loginToCompleteOrder;

  /// No description provided for @loginToCompleteOrderDesc.
  ///
  /// In en, this message translates to:
  /// **'To complete your purchase, save your address, and track your order, please log in.'**
  String get loginToCompleteOrderDesc;

  /// No description provided for @saveAddressesFeature.
  ///
  /// In en, this message translates to:
  /// **'Save shipping addresses for faster checkout'**
  String get saveAddressesFeature;

  /// No description provided for @trackOrderFeature.
  ///
  /// In en, this message translates to:
  /// **'Track order status step by step'**
  String get trackOrderFeature;

  /// No description provided for @easyReturnsFeature.
  ///
  /// In en, this message translates to:
  /// **'Manage returns easily'**
  String get easyReturnsFeature;

  /// No description provided for @loginBtn.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginBtn;

  /// No description provided for @createAccountBtn.
  ///
  /// In en, this message translates to:
  /// **'Create a new account'**
  String get createAccountBtn;

  /// No description provided for @shippingAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Shipping Address'**
  String get shippingAddressTitle;

  /// No description provided for @addBtn.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addBtn;

  /// No description provided for @addNewAddressBtn.
  ///
  /// In en, this message translates to:
  /// **'Add a new address'**
  String get addNewAddressBtn;

  /// No description provided for @defaultAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultAddressLabel;

  /// No description provided for @supplierLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplierLabel;

  /// No description provided for @processingProducts.
  ///
  /// In en, this message translates to:
  /// **'Processing products...'**
  String get processingProducts;

  /// No description provided for @shippingMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Shipping Method'**
  String get shippingMethodTitle;

  /// No description provided for @noShippingOptions.
  ///
  /// In en, this message translates to:
  /// **'No shipping options available for this address'**
  String get noShippingOptions;

  /// No description provided for @arrivesIn.
  ///
  /// In en, this message translates to:
  /// **'Arrives in'**
  String get arrivesIn;

  /// No description provided for @daysLabel.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysLabel;

  /// No description provided for @paymentMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethodTitle;

  /// No description provided for @creditCardMada.
  ///
  /// In en, this message translates to:
  /// **'Credit Card / Mada'**
  String get creditCardMada;

  /// No description provided for @noSavedCards.
  ///
  /// In en, this message translates to:
  /// **'No saved cards'**
  String get noSavedCards;

  /// No description provided for @addNewCardBtn.
  ///
  /// In en, this message translates to:
  /// **'Add a new card'**
  String get addNewCardBtn;

  /// No description provided for @cashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery'**
  String get cashOnDelivery;

  /// No description provided for @feeLabel.
  ///
  /// In en, this message translates to:
  /// **'fee'**
  String get feeLabel;

  /// No description provided for @payBtn.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get payBtn;

  /// No description provided for @subtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotalLabel;

  /// No description provided for @shippingCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Shipping Cost'**
  String get shippingCostLabel;

  /// No description provided for @codFeeDisplay.
  ///
  /// In en, this message translates to:
  /// **'COD Fee'**
  String get codFeeDisplay;

  /// No description provided for @grandTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotalLabel;

  /// No description provided for @secureTransactions.
  ///
  /// In en, this message translates to:
  /// **'All transactions are 100% secure and encrypted'**
  String get secureTransactions;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @searchCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a category...'**
  String get searchCategoryHint;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// No description provided for @noCategoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No matching categories found'**
  String get noCategoriesFound;

  /// No description provided for @productsLabel.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsLabel;

  /// No description provided for @noProductsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No products currently available in this category'**
  String get noProductsInCategory;

  /// No description provided for @ordersLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load orders, swipe down to refresh'**
  String get ordersLoadError;

  /// No description provided for @myOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrdersTitle;

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tabAll;

  /// No description provided for @tabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get tabActive;

  /// No description provided for @tabShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get tabShipped;

  /// No description provided for @tabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tabCompleted;

  /// No description provided for @tabCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get tabCancelled;

  /// No description provided for @retryBtn.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryBtn;

  /// No description provided for @noOrdersHere.
  ///
  /// In en, this message translates to:
  /// **'No orders found here'**
  String get noOrdersHere;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get statusProcessing;

  /// No description provided for @statusShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get statusShipped;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @orderNumberPrefix.
  ///
  /// In en, this message translates to:
  /// **'Order #'**
  String get orderNumberPrefix;

  /// No description provided for @totalOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalOrderLabel;

  /// No description provided for @trackOrderBtn.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get trackOrderBtn;

  /// No description provided for @orderDetailsBtn.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get orderDetailsBtn;

  /// No description provided for @orderDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetailsTitle;

  /// No description provided for @shipmentContentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Shipment Contents'**
  String get shipmentContentsLabel;

  /// No description provided for @paymentDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Details'**
  String get paymentDetailsLabel;

  /// No description provided for @orderNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Number: '**
  String get orderNumberLabel;

  /// No description provided for @orderDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get orderDateLabel;

  /// No description provided for @itemsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of Items'**
  String get itemsCountLabel;

  /// No description provided for @productsCountSuffix.
  ///
  /// In en, this message translates to:
  /// **'products'**
  String get productsCountSuffix;

  /// No description provided for @editBtn.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editBtn;

  /// No description provided for @rateProductBtn.
  ///
  /// In en, this message translates to:
  /// **'Rate Product'**
  String get rateProductBtn;

  /// No description provided for @shippingFeesLabel.
  ///
  /// In en, this message translates to:
  /// **'Shipping Fees'**
  String get shippingFeesLabel;

  /// No description provided for @freeLabel.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freeLabel;

  /// No description provided for @trackShipmentBtn.
  ///
  /// In en, this message translates to:
  /// **'Track Shipment'**
  String get trackShipmentBtn;

  /// No description provided for @errorOopsLabel.
  ///
  /// In en, this message translates to:
  /// **'Oops, something went wrong'**
  String get errorOopsLabel;

  /// No description provided for @failedToLoadOrderDetailsMsg.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the order details'**
  String get failedToLoadOrderDetailsMsg;

  /// No description provided for @editYourRating.
  ///
  /// In en, this message translates to:
  /// **'Edit your rating'**
  String get editYourRating;

  /// No description provided for @howWasTheProduct.
  ///
  /// In en, this message translates to:
  /// **'How was the product?'**
  String get howWasTheProduct;

  /// No description provided for @shareYourExperienceHint.
  ///
  /// In en, this message translates to:
  /// **'Share your experience (optional)...'**
  String get shareYourExperienceHint;

  /// No description provided for @updateRatingBtn.
  ///
  /// In en, this message translates to:
  /// **'Update Rating'**
  String get updateRatingBtn;

  /// No description provided for @submitRatingBtn.
  ///
  /// In en, this message translates to:
  /// **'Submit Rating'**
  String get submitRatingBtn;

  /// No description provided for @processingRatingMsg.
  ///
  /// In en, this message translates to:
  /// **'Processing rating...'**
  String get processingRatingMsg;

  /// No description provided for @ratingUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your rating has been updated!'**
  String get ratingUpdatedSuccess;

  /// No description provided for @thankYouMsg.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get thankYouMsg;

  /// No description provided for @dataUpdatedMsg.
  ///
  /// In en, this message translates to:
  /// **'Your data has been updated'**
  String get dataUpdatedMsg;

  /// No description provided for @sendFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Failed to send'**
  String get sendFailedMsg;

  /// No description provided for @opinionSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your review was saved successfully'**
  String get opinionSavedSuccess;

  /// No description provided for @trackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Tracking'**
  String get trackingTitle;

  /// No description provided for @failedToLoadData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data'**
  String get failedToLoadData;

  /// No description provided for @orderStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Status'**
  String get orderStatusTitle;

  /// No description provided for @orderCancelledMsg.
  ///
  /// In en, this message translates to:
  /// **'This order has been cancelled'**
  String get orderCancelledMsg;

  /// No description provided for @shipmentNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Shipment Number: '**
  String get shipmentNumberLabel;

  /// No description provided for @currentStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Status: '**
  String get currentStatusLabel;

  /// No description provided for @step1Title.
  ///
  /// In en, this message translates to:
  /// **'Order Received'**
  String get step1Title;

  /// No description provided for @step1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'We have received your order and await confirmation'**
  String get step1Subtitle;

  /// No description provided for @step2Title.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get step2Title;

  /// No description provided for @step2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Products are being prepared and packed'**
  String get step2Subtitle;

  /// No description provided for @step3Title.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get step3Title;

  /// No description provided for @step3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Shipment is with the courier on the way to you'**
  String get step3Subtitle;

  /// No description provided for @step4Title.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get step4Title;

  /// No description provided for @step4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'We hope you enjoy your product'**
  String get step4Subtitle;

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// No description provided for @soonLabel.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get soonLabel;

  /// No description provided for @inProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'In progress...'**
  String get inProgressLabel;

  /// No description provided for @cardDeletedMsg.
  ///
  /// In en, this message translates to:
  /// **'Card deleted successfully'**
  String get cardDeletedMsg;

  /// No description provided for @cardHolderLabel.
  ///
  /// In en, this message translates to:
  /// **'CARD HOLDER'**
  String get cardHolderLabel;

  /// No description provided for @expiresLabel.
  ///
  /// In en, this message translates to:
  /// **'EXPIRES'**
  String get expiresLabel;

  /// No description provided for @addCardBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Card'**
  String get addCardBtn;

  /// No description provided for @addNewCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Card'**
  String get addNewCardTitle;

  /// No description provided for @fillAllFieldsMsg.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get fillAllFieldsMsg;

  /// No description provided for @invalidDateFormatMsg.
  ///
  /// In en, this message translates to:
  /// **'Invalid date format'**
  String get invalidDateFormatMsg;

  /// No description provided for @cardSavedSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Card saved successfully ✅'**
  String get cardSavedSuccessMsg;

  /// No description provided for @cardErrorMsg.
  ///
  /// In en, this message translates to:
  /// **'Card Error: '**
  String get cardErrorMsg;

  /// No description provided for @verifyCardDataMsg.
  ///
  /// In en, this message translates to:
  /// **'Please verify your card data'**
  String get verifyCardDataMsg;

  /// No description provided for @cardNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get cardNumberLabel;

  /// No description provided for @expiryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDateLabel;

  /// No description provided for @cardHolderNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Card Holder Name'**
  String get cardHolderNameLabel;

  /// No description provided for @saveCardBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Card'**
  String get saveCardBtn;

  /// No description provided for @errorLoadingProductsMsg.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading products'**
  String get errorLoadingProductsMsg;

  /// No description provided for @filterLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterLabel;

  /// No description provided for @sortLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get sortLatest;

  /// No description provided for @sortPriceAsc.
  ///
  /// In en, this message translates to:
  /// **'Price: Low to High'**
  String get sortPriceAsc;

  /// No description provided for @sortPriceDesc.
  ///
  /// In en, this message translates to:
  /// **'Price: High to Low'**
  String get sortPriceDesc;

  /// No description provided for @sortRating.
  ///
  /// In en, this message translates to:
  /// **'Highest Rated'**
  String get sortRating;

  /// No description provided for @unknownErrorMsg.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get unknownErrorMsg;

  /// No description provided for @noProductsMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No products match the filter'**
  String get noProductsMatchFilter;

  /// No description provided for @clearAllFiltersBtn.
  ///
  /// In en, this message translates to:
  /// **'Clear all filters'**
  String get clearAllFiltersBtn;

  /// No description provided for @productNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Product not available'**
  String get productNotAvailable;

  /// No description provided for @shareProductIntro.
  ///
  /// In en, this message translates to:
  /// **'Check out this amazing product on Linyora:'**
  String get shareProductIntro;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @addedToCartSuccess.
  ///
  /// In en, this message translates to:
  /// **'Added to cart successfully'**
  String get addedToCartSuccess;

  /// No description provided for @continueShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue Shopping'**
  String get continueShopping;

  /// No description provided for @viewCartBtn.
  ///
  /// In en, this message translates to:
  /// **'View Cart'**
  String get viewCartBtn;

  /// No description provided for @discountOff.
  ///
  /// In en, this message translates to:
  /// **'% Off'**
  String get discountOff;

  /// No description provided for @noReviewsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'no Reviews'**
  String get noReviewsYetTitle;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @reviewCountLabel.
  ///
  /// In en, this message translates to:
  /// **'review'**
  String get reviewCountLabel;

  /// No description provided for @chooseSpecifications.
  ///
  /// In en, this message translates to:
  /// **'Choose Specifications'**
  String get chooseSpecifications;

  /// No description provided for @sellerPrefix.
  ///
  /// In en, this message translates to:
  /// **'Seller: '**
  String get sellerPrefix;

  /// No description provided for @trustedSeller.
  ///
  /// In en, this message translates to:
  /// **'Trusted'**
  String get trustedSeller;

  /// No description provided for @visitStoreBtn.
  ///
  /// In en, this message translates to:
  /// **'Visit Store'**
  String get visitStoreBtn;

  /// No description provided for @productDescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Description'**
  String get productDescriptionTitle;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read More'**
  String get readMore;

  /// No description provided for @addToCartBtn.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCartBtn;

  /// No description provided for @buyNowBtn.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNowBtn;

  /// No description provided for @beFirstToReview.
  ///
  /// In en, this message translates to:
  /// **'Be the first to review this product!'**
  String get beFirstToReview;

  /// No description provided for @customerReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Reviews'**
  String get customerReviewsTitle;

  /// No description provided for @viewAllReviewsBtn.
  ///
  /// In en, this message translates to:
  /// **'View All Reviews'**
  String get viewAllReviewsBtn;

  /// No description provided for @helpfulReviewBtn.
  ///
  /// In en, this message translates to:
  /// **'Helpful'**
  String get helpfulReviewBtn;

  /// No description provided for @reportReviewBtn.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportReviewBtn;

  /// No description provided for @filterResults.
  ///
  /// In en, this message translates to:
  /// **'Filter Results'**
  String get filterResults;

  /// No description provided for @loadingOptions.
  ///
  /// In en, this message translates to:
  /// **'Loading options...'**
  String get loadingOptions;

  /// No description provided for @resetBtn.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetBtn;

  /// No description provided for @brandsLabel.
  ///
  /// In en, this message translates to:
  /// **'Brands'**
  String get brandsLabel;

  /// No description provided for @selectedLabel.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selectedLabel;

  /// No description provided for @ratingLabel.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get ratingLabel;

  /// No description provided for @colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color: '**
  String get colorLabel;

  /// No description provided for @applyFilterBtn.
  ///
  /// In en, this message translates to:
  /// **'Apply Filter'**
  String get applyFilterBtn;

  /// No description provided for @addProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProductTitle;

  /// No description provided for @editProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProductTitle;

  /// No description provided for @dropshippingAlertMsg.
  ///
  /// In en, this message translates to:
  /// **'This is an imported product. You can only edit the price and description, while stock and images are synced automatically from the supplier.'**
  String get dropshippingAlertMsg;

  /// No description provided for @basicInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInfoTitle;

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productNameLabel;

  /// No description provided for @originalNameFromSupplierHint.
  ///
  /// In en, this message translates to:
  /// **'Original name from supplier'**
  String get originalNameFromSupplierHint;

  /// No description provided for @brandLabel.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brandLabel;

  /// No description provided for @productDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Description'**
  String get productDescriptionLabel;

  /// No description provided for @productStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Status (Active/Draft)'**
  String get productStatusLabel;

  /// No description provided for @productVariantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Variants'**
  String get productVariantsTitle;

  /// No description provided for @sellingPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get sellingPriceLabel;

  /// No description provided for @compareAtPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Compare at Price'**
  String get compareAtPriceLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @managedAutomaticallyHint.
  ///
  /// In en, this message translates to:
  /// **'Managed automatically'**
  String get managedAutomaticallyHint;

  /// No description provided for @noImagesFromSupplierMsg.
  ///
  /// In en, this message translates to:
  /// **'No images available from the supplier.'**
  String get noImagesFromSupplierMsg;

  /// No description provided for @productImagesReadOnlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Images (View Only)'**
  String get productImagesReadOnlyLabel;

  /// No description provided for @variantImagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Variant Images'**
  String get variantImagesLabel;

  /// No description provided for @uploadImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImageLabel;

  /// No description provided for @categoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesLabel;

  /// No description provided for @selectCategoriesHint.
  ///
  /// In en, this message translates to:
  /// **'Select categories...'**
  String get selectCategoriesHint;

  /// No description provided for @addNewVariantBtn.
  ///
  /// In en, this message translates to:
  /// **'Add New Variant'**
  String get addNewVariantBtn;

  /// No description provided for @selectCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Categories'**
  String get selectCategoriesTitle;

  /// No description provided for @doneBtn.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneBtn;

  /// No description provided for @noResultsMsg.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResultsMsg;

  /// No description provided for @requiredFieldMsg.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredFieldMsg;

  /// No description provided for @cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelBtn;

  /// No description provided for @saveProductBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Product'**
  String get saveProductBtn;

  /// No description provided for @selectOneCategoryAtLeastMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one category'**
  String get selectOneCategoryAtLeastMsg;

  /// No description provided for @savedSuccessfullyMsg.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get savedSuccessfullyMsg;

  /// No description provided for @merchantProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get merchantProductsTitle;

  /// No description provided for @deleteProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProductTitle;

  /// No description provided for @deleteProductContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this product?'**
  String get deleteProductContent;

  /// No description provided for @deletedSuccessfullyMsg.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get deletedSuccessfullyMsg;

  /// No description provided for @deletionFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Deletion failed'**
  String get deletionFailedMsg;

  /// No description provided for @noPromotionTiersAvailableMsg.
  ///
  /// In en, this message translates to:
  /// **'No promotion tiers are currently available'**
  String get noPromotionTiersAvailableMsg;

  /// No description provided for @productPromotedSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Product promoted successfully! 🚀'**
  String get productPromotedSuccessMsg;

  /// No description provided for @totalProductsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get totalProductsLabel;

  /// No description provided for @activeProductsLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Products'**
  String get activeProductsLabel;

  /// No description provided for @lowStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStockLabel;

  /// No description provided for @promotedLabel.
  ///
  /// In en, this message translates to:
  /// **'Promoted'**
  String get promotedLabel;

  /// No description provided for @endsTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'ends today'**
  String get endsTodayLabel;

  /// No description provided for @productDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetailsLabel;

  /// No description provided for @previewBtn.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewBtn;

  /// No description provided for @promoteBtn.
  ///
  /// In en, this message translates to:
  /// **'Promote'**
  String get promoteBtn;

  /// No description provided for @activeStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatusLabel;

  /// No description provided for @draftStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draftStatusLabel;

  /// No description provided for @noProductsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get noProductsYetTitle;

  /// No description provided for @startAddingProductsMsg.
  ///
  /// In en, this message translates to:
  /// **'Add your first product and start selling!'**
  String get startAddingProductsMsg;

  /// No description provided for @addNewProductBtn.
  ///
  /// In en, this message translates to:
  /// **'Add New Product'**
  String get addNewProductBtn;

  /// No description provided for @promoteProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Promote Product'**
  String get promoteProductTitle;

  /// No description provided for @choosePackageForProductMsg.
  ///
  /// In en, this message translates to:
  /// **'Choose a package to promote the product: '**
  String get choosePackageForProductMsg;

  /// No description provided for @similarProducts.
  ///
  /// In en, this message translates to:
  /// **'Similar Products'**
  String get similarProducts;

  /// No description provided for @moreFromThisStore.
  ///
  /// In en, this message translates to:
  /// **'More from this store'**
  String get moreFromThisStore;

  /// No description provided for @storeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Store not found'**
  String get storeNotFound;

  /// No description provided for @shareStoreIntro.
  ///
  /// In en, this message translates to:
  /// **'🛍️ Shop from '**
  String get shareStoreIntro;

  /// No description provided for @shareStoreMid.
  ///
  /// In en, this message translates to:
  /// **'\'s amazing store on Linyora!\n\nExplore the latest products and exclusive offers: 👇\n'**
  String get shareStoreMid;

  /// No description provided for @shareStoreSubject.
  ///
  /// In en, this message translates to:
  /// **'Store on Linyora'**
  String get shareStoreSubject;

  /// No description provided for @followingBtn.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followingBtn;

  /// No description provided for @followBtn.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get followBtn;

  /// No description provided for @shareStoreTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share Store'**
  String get shareStoreTooltip;

  /// No description provided for @defaultMerchantName.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get defaultMerchantName;

  /// No description provided for @verifiedMerchantBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified Merchant'**
  String get verifiedMerchantBadge;

  /// No description provided for @ratingBadge.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get ratingBadge;

  /// No description provided for @fastDeliveryBadge.
  ///
  /// In en, this message translates to:
  /// **'Fast Delivery'**
  String get fastDeliveryBadge;

  /// No description provided for @followersStat.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followersStat;

  /// No description provided for @followingStat.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followingStat;

  /// No description provided for @productsStat.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsStat;

  /// No description provided for @productsHeader.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsHeader;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @reelsTab.
  ///
  /// In en, this message translates to:
  /// **'Reels'**
  String get reelsTab;

  /// No description provided for @servicesTab.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get servicesTab;

  /// No description provided for @unfollowBtn.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollowBtn;

  /// No description provided for @shareProfileIntro.
  ///
  /// In en, this message translates to:
  /// **'🌟 Discover '**
  String get shareProfileIntro;

  /// No description provided for @shareProfileMid.
  ///
  /// In en, this message translates to:
  /// **'\'s profile on Linyora!\n\nBrowse exclusive portfolio and services here: 👇\n'**
  String get shareProfileMid;

  /// No description provided for @shareProfileSubject.
  ///
  /// In en, this message translates to:
  /// **'profile on Linyora'**
  String get shareProfileSubject;

  /// No description provided for @portfolioTab.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolioTab;

  /// No description provided for @noImagesMsg.
  ///
  /// In en, this message translates to:
  /// **'No images'**
  String get noImagesMsg;

  /// No description provided for @noReelsMsg.
  ///
  /// In en, this message translates to:
  /// **'No reels'**
  String get noReelsMsg;

  /// No description provided for @productsInThisVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Products in this video'**
  String get productsInThisVideoTitle;

  /// No description provided for @buyBtn.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buyBtn;

  /// No description provided for @watchThisVideoMsg.
  ///
  /// In en, this message translates to:
  /// **'Watch this video: '**
  String get watchThisVideoMsg;

  /// No description provided for @viewProductsBtn.
  ///
  /// In en, this message translates to:
  /// **'View Products'**
  String get viewProductsBtn;

  /// No description provided for @shareActionBtn.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareActionBtn;

  /// No description provided for @shopActionBtn.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shopActionBtn;

  /// No description provided for @shareSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Shared successfully!'**
  String get shareSuccessMsg;

  /// No description provided for @failedToSendCommentMsg.
  ///
  /// In en, this message translates to:
  /// **'Failed to send comment'**
  String get failedToSendCommentMsg;

  /// No description provided for @commentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// No description provided for @noCommentsYetMsg.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noCommentsYetMsg;

  /// No description provided for @addCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addCommentHint;

  /// No description provided for @specialOffersTitle.
  ///
  /// In en, this message translates to:
  /// **'Special Offers 🔥'**
  String get specialOffersTitle;

  /// No description provided for @noOffersCurrently.
  ///
  /// In en, this message translates to:
  /// **'No offers currently available'**
  String get noOffersCurrently;

  /// No description provided for @hotBadge.
  ///
  /// In en, this message translates to:
  /// **'HOT 🔥'**
  String get hotBadge;

  /// No description provided for @endingSoon.
  ///
  /// In en, this message translates to:
  /// **'Ending soon'**
  String get endingSoon;

  /// No description provided for @soldPercentageLabel.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get soldPercentageLabel;

  /// No description provided for @endsInLabel.
  ///
  /// In en, this message translates to:
  /// **'Ends in '**
  String get endsInLabel;

  /// No description provided for @emptyWishlistMsg.
  ///
  /// In en, this message translates to:
  /// **'Your wishlist is empty'**
  String get emptyWishlistMsg;

  /// No description provided for @myAddressesTitle.
  ///
  /// In en, this message translates to:
  /// **'My Addresses'**
  String get myAddressesTitle;

  /// No description provided for @noSavedAddressesMsg.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses'**
  String get noSavedAddressesMsg;

  /// No description provided for @defaultAddressBadge.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultAddressBadge;

  /// No description provided for @deleteAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Address'**
  String get deleteAddressTitle;

  /// No description provided for @deleteAddressConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this address?'**
  String get deleteAddressConfirmMsg;

  /// No description provided for @addNewAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'New Address'**
  String get addNewAddressTitle;

  /// No description provided for @editAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get editAddressTitle;

  /// No description provided for @selectLocationWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Please select the delivery location on the map'**
  String get selectLocationWarning;

  /// No description provided for @addressSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Address saved successfully'**
  String get addressSavedSuccess;

  /// No description provided for @saveFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Failed to save ❌'**
  String get saveFailedMsg;

  /// No description provided for @deliveryLocationSection.
  ///
  /// In en, this message translates to:
  /// **'Delivery Location'**
  String get deliveryLocationSection;

  /// No description provided for @recipientDataSection.
  ///
  /// In en, this message translates to:
  /// **'Recipient Details'**
  String get recipientDataSection;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Mohammed Ahmed'**
  String get fullNameHint;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'05xxxxxxxx'**
  String get phoneHint;

  /// No description provided for @addressDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Address Details'**
  String get addressDetailsSection;

  /// No description provided for @countryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryLabel;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @regionDistrictLabel.
  ///
  /// In en, this message translates to:
  /// **'Region / District'**
  String get regionDistrictLabel;

  /// No description provided for @postalCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get postalCodeLabel;

  /// No description provided for @streetNameDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Street Name / House Description'**
  String get streetNameDescLabel;

  /// No description provided for @streetNameHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Next to the mosque...'**
  String get streetNameHint;

  /// No description provided for @setAsDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Set as default address'**
  String get setAsDefaultLabel;

  /// No description provided for @setAsDefaultDesc.
  ///
  /// In en, this message translates to:
  /// **'This address will be used automatically for upcoming orders'**
  String get setAsDefaultDesc;

  /// No description provided for @locationSelectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Location selected successfully'**
  String get locationSelectedSuccess;

  /// No description provided for @tapToSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap to select location on map'**
  String get tapToSelectLocation;

  /// No description provided for @coordinatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Coordinates: '**
  String get coordinatesLabel;

  /// No description provided for @locationRequiredDesc.
  ///
  /// In en, this message translates to:
  /// **'A necessary step to deliver the order to your door'**
  String get locationRequiredDesc;

  /// No description provided for @saveAddressBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Address'**
  String get saveAddressBtn;

  /// No description provided for @updateDataBtn.
  ///
  /// In en, this message translates to:
  /// **'Update Data'**
  String get updateDataBtn;

  /// No description provided for @influencerDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get influencerDashboardTitle;

  /// No description provided for @accountVerification.
  ///
  /// In en, this message translates to:
  /// **'Account Verification'**
  String get accountVerification;

  /// No description provided for @myOffers.
  ///
  /// In en, this message translates to:
  /// **'My Offers'**
  String get myOffers;

  /// No description provided for @reels.
  ///
  /// In en, this message translates to:
  /// **'Reels'**
  String get reels;

  /// No description provided for @collabRequests.
  ///
  /// In en, this message translates to:
  /// **'Collaboration Requests'**
  String get collabRequests;

  /// No description provided for @stories.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get stories;

  /// No description provided for @analyticsAndPerformance.
  ///
  /// In en, this message translates to:
  /// **'Analytics & Performance'**
  String get analyticsAndPerformance;

  /// No description provided for @financialWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get financialWallet;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @currentPackage.
  ///
  /// In en, this message translates to:
  /// **'Current Package'**
  String get currentPackage;

  /// No description provided for @upgradeAccount.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Account'**
  String get upgradeAccount;

  /// No description provided for @bankAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get bankAccount;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @exclusiveFeature.
  ///
  /// In en, this message translates to:
  /// **'Exclusive Feature'**
  String get exclusiveFeature;

  /// No description provided for @featureLockedPart1.
  ///
  /// In en, this message translates to:
  /// **'The feature ('**
  String get featureLockedPart1;

  /// No description provided for @featureLockedPart2.
  ///
  /// In en, this message translates to:
  /// **') is available only for subscribers. Upgrade your account to access professional tools.'**
  String get featureLockedPart2;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notNow;

  /// No description provided for @upgradeNow.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Now'**
  String get upgradeNow;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBack;

  /// No description provided for @defaultInfluencerName.
  ///
  /// In en, this message translates to:
  /// **'Influencer'**
  String get defaultInfluencerName;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// No description provided for @activeRequests.
  ///
  /// In en, this message translates to:
  /// **'Active Requests'**
  String get activeRequests;

  /// No description provided for @monthlyEarnings.
  ///
  /// In en, this message translates to:
  /// **'Monthly Earnings'**
  String get monthlyEarnings;

  /// No description provided for @viewsLabel.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get viewsLabel;

  /// No description provided for @requestUnit.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get requestUnit;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @noActivities.
  ///
  /// In en, this message translates to:
  /// **'No activities'**
  String get noActivities;

  /// No description provided for @responseRate.
  ///
  /// In en, this message translates to:
  /// **'Response Rate'**
  String get responseRate;

  /// No description provided for @excellentInteraction.
  ///
  /// In en, this message translates to:
  /// **'Your interaction with requests is excellent!'**
  String get excellentInteraction;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @changeLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get changeLanguageLabel;

  /// No description provided for @confirmingSubscriptionMsg.
  ///
  /// In en, this message translates to:
  /// **'⏳ Confirming subscription with the bank...'**
  String get confirmingSubscriptionMsg;

  /// No description provided for @subscriptionActivatedSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'✅ Congratulations! Your new package has been successfully activated'**
  String get subscriptionActivatedSuccessMsg;

  /// No description provided for @operationFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'❌ Operation failed: '**
  String get operationFailedMsg;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorPrefix;

  /// No description provided for @subscriptionPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription Plans'**
  String get subscriptionPlansTitle;

  /// No description provided for @discoverPerfectPackage.
  ///
  /// In en, this message translates to:
  /// **'Discover your perfect package'**
  String get discoverPerfectPackage;

  /// No description provided for @packageFeaturesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enjoy exclusive features and advanced tools to grow your business'**
  String get packageFeaturesSubtitle;

  /// No description provided for @yourCurrentPackage.
  ///
  /// In en, this message translates to:
  /// **'✅ Your current package'**
  String get yourCurrentPackage;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'\n/ month'**
  String get perMonth;

  /// No description provided for @currentlySubscribedBtn.
  ///
  /// In en, this message translates to:
  /// **'Currently Subscribed ✅'**
  String get currentlySubscribedBtn;

  /// No description provided for @subscribeNowBtn.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscribeNowBtn;

  /// No description provided for @mostRequestedBadge.
  ///
  /// In en, this message translates to:
  /// **'Most Requested 🔥'**
  String get mostRequestedBadge;

  /// No description provided for @autoRenewalCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-renewal Cancelled'**
  String get autoRenewalCancelledTitle;

  /// No description provided for @autoRenewalCancelledDesc.
  ///
  /// In en, this message translates to:
  /// **'You have successfully cancelled the auto-renewal for your subscription.\n\nYou can continue to enjoy the features of your current package until its expiration date, and no future deductions will be made.'**
  String get autoRenewalCancelledDesc;

  /// No description provided for @backToHomeBtn.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHomeBtn;

  /// No description provided for @incompletePaymentDataMsg.
  ///
  /// In en, this message translates to:
  /// **'Incomplete payment data'**
  String get incompletePaymentDataMsg;

  /// No description provided for @unknownStateMsg.
  ///
  /// In en, this message translates to:
  /// **'Unknown state: '**
  String get unknownStateMsg;

  /// No description provided for @paymentFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Payment failed: '**
  String get paymentFailedMsg;

  /// No description provided for @subscriptionFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Subscription failed: '**
  String get subscriptionFailedMsg;

  /// No description provided for @operationCancelledMsg.
  ///
  /// In en, this message translates to:
  /// **'Operation cancelled'**
  String get operationCancelledMsg;

  /// No description provided for @serverConnectionFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to the server'**
  String get serverConnectionFailedMsg;

  /// No description provided for @unexpectedErrorMsg.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unexpectedErrorMsg;

  /// No description provided for @errorProcessingRequestMsg.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while processing the request'**
  String get errorProcessingRequestMsg;

  /// No description provided for @unspecifiedDate.
  ///
  /// In en, this message translates to:
  /// **'Unspecified'**
  String get unspecifiedDate;

  /// No description provided for @cancelSubscriptionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription?'**
  String get cancelSubscriptionDialogTitle;

  /// No description provided for @cancelSubscriptionDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel your subscription? You will lose access to paid features at the end of the current period.'**
  String get cancelSubscriptionDialogDesc;

  /// No description provided for @undoBtn.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoBtn;

  /// No description provided for @yesCancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancelBtn;

  /// No description provided for @noActiveSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'No active subscription'**
  String get noActiveSubscriptionTitle;

  /// No description provided for @noActiveSubscriptionDesc.
  ///
  /// In en, this message translates to:
  /// **'Subscribe now to one of Linyora\'s packages to get dropshipping privileges and exclusive features to grow your business.'**
  String get noActiveSubscriptionDesc;

  /// No description provided for @browseSubscriptionPlansBtn.
  ///
  /// In en, this message translates to:
  /// **'Browse Subscription Plans'**
  String get browseSubscriptionPlansBtn;

  /// No description provided for @swipeDownToRefreshMsg.
  ///
  /// In en, this message translates to:
  /// **'Swipe down to refresh if you just subscribed'**
  String get swipeDownToRefreshMsg;

  /// No description provided for @unknownPackage.
  ///
  /// In en, this message translates to:
  /// **'Unknown Package'**
  String get unknownPackage;

  /// No description provided for @activeSubscriptionBadge.
  ///
  /// In en, this message translates to:
  /// **'Active Subscription'**
  String get activeSubscriptionBadge;

  /// No description provided for @inactiveSubscriptionBadge.
  ///
  /// In en, this message translates to:
  /// **'Inactive Subscription'**
  String get inactiveSubscriptionBadge;

  /// No description provided for @currentPackageTitle.
  ///
  /// In en, this message translates to:
  /// **'Current Package'**
  String get currentPackageTitle;

  /// No description provided for @startDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDateLabel;

  /// No description provided for @renewalDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Renewal Date'**
  String get renewalDateLabel;

  /// No description provided for @dropshippingEnabledMsg.
  ///
  /// In en, this message translates to:
  /// **'Dropshipping access enabled ✅'**
  String get dropshippingEnabledMsg;

  /// No description provided for @upgradePackageBtn.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Package Now'**
  String get upgradePackageBtn;

  /// No description provided for @processingMsg.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processingMsg;

  /// No description provided for @cancelSubscriptionRenewalBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription Renewal'**
  String get cancelSubscriptionRenewalBtn;

  /// No description provided for @statusChangedToMsg.
  ///
  /// In en, this message translates to:
  /// **'Status changed to '**
  String get statusChangedToMsg;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @pausedStatus.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get pausedStatus;

  /// No description provided for @deleteOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Offer'**
  String get deleteOfferTitle;

  /// No description provided for @deleteOfferConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this offer? This action cannot be undone.'**
  String get deleteOfferConfirmMsg;

  /// No description provided for @activeOffersCount.
  ///
  /// In en, this message translates to:
  /// **' Active Offers'**
  String get activeOffersCount;

  /// No description provided for @addNewOfferBtn.
  ///
  /// In en, this message translates to:
  /// **'Add New Offer'**
  String get addNewOfferBtn;

  /// No description provided for @noOffersCurrentlyMsg.
  ///
  /// In en, this message translates to:
  /// **'No offers currently available'**
  String get noOffersCurrentlyMsg;

  /// No description provided for @startAddingPackagesMsg.
  ///
  /// In en, this message translates to:
  /// **'Start adding your packages to attract clients'**
  String get startAddingPackagesMsg;

  /// No description provided for @disableOfferBtn.
  ///
  /// In en, this message translates to:
  /// **'Disable Offer'**
  String get disableOfferBtn;

  /// No description provided for @enableOfferBtn.
  ///
  /// In en, this message translates to:
  /// **'Enable Offer'**
  String get enableOfferBtn;

  /// No description provided for @visibleToClientsBadge.
  ///
  /// In en, this message translates to:
  /// **'Visible to Clients'**
  String get visibleToClientsBadge;

  /// No description provided for @hiddenBadge.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hiddenBadge;

  /// No description provided for @infiniteRevisions.
  ///
  /// In en, this message translates to:
  /// **'Infinite Revisions'**
  String get infiniteRevisions;

  /// No description provided for @revisionsCount.
  ///
  /// In en, this message translates to:
  /// **' Revisions'**
  String get revisionsCount;

  /// No description provided for @editOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Offer'**
  String get editOfferTitle;

  /// No description provided for @saveBtn.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveBtn;

  /// No description provided for @offerDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Offer Details'**
  String get offerDetailsSection;

  /// No description provided for @packagesAndPricesSection.
  ///
  /// In en, this message translates to:
  /// **'Packages and Prices'**
  String get packagesAndPricesSection;

  /// No description provided for @addLevelBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Level'**
  String get addLevelBtn;

  /// No description provided for @saveOfferBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Offer'**
  String get saveOfferBtn;

  /// No description provided for @offerTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Offer Title'**
  String get offerTitleLabel;

  /// No description provided for @offerTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Professional Product Photoshoot'**
  String get offerTitleHint;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @chooseOfferCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Choose offer category'**
  String get chooseOfferCategoryHint;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Explain the offer details and what the client will get...'**
  String get descriptionHint;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level '**
  String get levelLabel;

  /// No description provided for @packageNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Package Name'**
  String get packageNameLabel;

  /// No description provided for @packageNameHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Basic'**
  String get packageNameHint;

  /// No description provided for @priceSALLabel.
  ///
  /// In en, this message translates to:
  /// **'Price (SAR)'**
  String get priceSALLabel;

  /// No description provided for @deliveryDurationDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Duration (Days)'**
  String get deliveryDurationDaysLabel;

  /// No description provided for @revisionsNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of Revisions'**
  String get revisionsNumberLabel;

  /// No description provided for @revisionsHint.
  ///
  /// In en, this message translates to:
  /// **'(-1 for infinite revisions)'**
  String get revisionsHint;

  /// No description provided for @featuresLabel.
  ///
  /// In en, this message translates to:
  /// **'Features:'**
  String get featuresLabel;

  /// No description provided for @featureHint.
  ///
  /// In en, this message translates to:
  /// **'Feature (Example: 4K Quality Video)'**
  String get featureHint;

  /// No description provided for @addFeatureBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Feature'**
  String get addFeatureBtn;

  /// No description provided for @atLeastOnePackageMsg.
  ///
  /// In en, this message translates to:
  /// **'The offer must contain at least one package'**
  String get atLeastOnePackageMsg;

  /// No description provided for @photoSessionCategory.
  ///
  /// In en, this message translates to:
  /// **'Photoshoot'**
  String get photoSessionCategory;

  /// No description provided for @promoVideoCategory.
  ///
  /// In en, this message translates to:
  /// **'Promo Video'**
  String get promoVideoCategory;

  /// No description provided for @productReviewCategory.
  ///
  /// In en, this message translates to:
  /// **'Product Review'**
  String get productReviewCategory;

  /// No description provided for @eventAttendanceCategory.
  ///
  /// In en, this message translates to:
  /// **'Event Attendance'**
  String get eventAttendanceCategory;

  /// No description provided for @storyAdCategory.
  ///
  /// In en, this message translates to:
  /// **'Story Ad'**
  String get storyAdCategory;

  /// No description provided for @otherCategory.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherCategory;

  /// No description provided for @basicPackageName.
  ///
  /// In en, this message translates to:
  /// **'Basic Package'**
  String get basicPackageName;

  /// No description provided for @newPackageName.
  ///
  /// In en, this message translates to:
  /// **'New Package'**
  String get newPackageName;

  /// No description provided for @uploadNewVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload New Video'**
  String get uploadNewVideoTitle;

  /// No description provided for @videoSizeExceeds100MBMsg.
  ///
  /// In en, this message translates to:
  /// **'Video size must be less than 100MB'**
  String get videoSizeExceeds100MBMsg;

  /// No description provided for @pleaseSelectVideoMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select a video'**
  String get pleaseSelectVideoMsg;

  /// No description provided for @videoUploadedSuccessfullyMsg.
  ///
  /// In en, this message translates to:
  /// **'Video uploaded successfully!'**
  String get videoUploadedSuccessfullyMsg;

  /// No description provided for @uploadFailedTryAgainMsg.
  ///
  /// In en, this message translates to:
  /// **'Upload failed, please try again'**
  String get uploadFailedTryAgainMsg;

  /// No description provided for @serverError500Msg.
  ///
  /// In en, this message translates to:
  /// **'Server error (500). Please check the database.'**
  String get serverError500Msg;

  /// No description provided for @videoTooLargeMsg.
  ///
  /// In en, this message translates to:
  /// **'Video size is too large'**
  String get videoTooLargeMsg;

  /// No description provided for @tapToSelectVideo.
  ///
  /// In en, this message translates to:
  /// **'Tap to select a video'**
  String get tapToSelectVideo;

  /// No description provided for @supportedVideoFormats.
  ///
  /// In en, this message translates to:
  /// **'MP4, MOV (Max 100MB)'**
  String get supportedVideoFormats;

  /// No description provided for @writeCatchyDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Write a catchy description for the video...'**
  String get writeCatchyDescriptionHint;

  /// No description provided for @availableProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Available Products'**
  String get availableProductsTitle;

  /// No description provided for @addProductBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProductBtn;

  /// No description provided for @noProductsSelectedMsg.
  ///
  /// In en, this message translates to:
  /// **'No products selected'**
  String get noProductsSelectedMsg;

  /// No description provided for @linkedToAgreementPrefix.
  ///
  /// In en, this message translates to:
  /// **'Linked to agreement #'**
  String get linkedToAgreementPrefix;

  /// No description provided for @publishVideoBtn.
  ///
  /// In en, this message translates to:
  /// **'Publish Video'**
  String get publishVideoBtn;

  /// No description provided for @noActiveAgreementsMsg.
  ///
  /// In en, this message translates to:
  /// **'No active agreements currently'**
  String get noActiveAgreementsMsg;

  /// No description provided for @mustAcceptAgreementFirstMsg.
  ///
  /// In en, this message translates to:
  /// **'You must accept a collaboration agreement with a merchant first'**
  String get mustAcceptAgreementFirstMsg;

  /// No description provided for @okBtn.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okBtn;

  /// No description provided for @chooseProductToPromoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a product to promote'**
  String get chooseProductToPromoteTitle;

  /// No description provided for @onlyAgreementProductsShownMsg.
  ///
  /// In en, this message translates to:
  /// **'Only products linked to your agreements are shown'**
  String get onlyAgreementProductsShownMsg;

  /// No description provided for @confirmSelectionBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm Selection'**
  String get confirmSelectionBtn;

  /// No description provided for @failedToFetchDataMsg.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch data'**
  String get failedToFetchDataMsg;

  /// No description provided for @deleteVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Video?'**
  String get deleteVideoTitle;

  /// No description provided for @deleteVideoConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this video? This action cannot be undone.'**
  String get deleteVideoConfirmMsg;

  /// No description provided for @errorDeletingMsg.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while deleting'**
  String get errorDeletingMsg;

  /// No description provided for @totalCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Count: '**
  String get totalCountLabel;

  /// No description provided for @activeCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Active: '**
  String get activeCountLabel;

  /// No description provided for @uploadVideoBtn.
  ///
  /// In en, this message translates to:
  /// **'Upload Video'**
  String get uploadVideoBtn;

  /// No description provided for @reelsManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Reels Management'**
  String get reelsManagementTitle;

  /// No description provided for @reelsManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and track your videos performance'**
  String get reelsManagementSubtitle;

  /// No description provided for @noVideosYetMsg.
  ///
  /// In en, this message translates to:
  /// **'No videos yet'**
  String get noVideosYetMsg;

  /// No description provided for @startUploadingVideosMsg.
  ///
  /// In en, this message translates to:
  /// **'Start uploading videos to showcase your products'**
  String get startUploadingVideosMsg;

  /// No description provided for @noTitleMsg.
  ///
  /// In en, this message translates to:
  /// **'No title'**
  String get noTitleMsg;

  /// No description provided for @viewsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get viewsCountLabel;

  /// No description provided for @likesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likesCountLabel;

  /// No description provided for @inactiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactiveStatus;

  /// No description provided for @videoUpdatedSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Video updated successfully'**
  String get videoUpdatedSuccessMsg;

  /// No description provided for @updateFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailedMsg;

  /// No description provided for @editVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Video'**
  String get editVideoTitle;

  /// No description provided for @writeNewDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Write a new description...'**
  String get writeNewDescriptionHint;

  /// No description provided for @rejectRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Request'**
  String get rejectRequestTitle;

  /// No description provided for @whyRejectRequestMsg.
  ///
  /// In en, this message translates to:
  /// **'Why do you want to reject the request from '**
  String get whyRejectRequestMsg;

  /// No description provided for @busyCurrentlyReason.
  ///
  /// In en, this message translates to:
  /// **'Currently busy'**
  String get busyCurrentlyReason;

  /// No description provided for @budgetNotSuitableReason.
  ///
  /// In en, this message translates to:
  /// **'Budget is not suitable'**
  String get budgetNotSuitableReason;

  /// No description provided for @otherReason.
  ///
  /// In en, this message translates to:
  /// **'Other reason'**
  String get otherReason;

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reasonLabel;

  /// No description provided for @writeReasonHereHint.
  ///
  /// In en, this message translates to:
  /// **'Write the reason here...'**
  String get writeReasonHereHint;

  /// No description provided for @confirmRejectionBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm Rejection'**
  String get confirmRejectionBtn;

  /// No description provided for @requestRejectedSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get requestRejectedSuccessMsg;

  /// No description provided for @agreementRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Agreement Requests'**
  String get agreementRequestsTitle;

  /// No description provided for @manageCollabRequestsDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage and track your requests with influencers'**
  String get manageCollabRequestsDesc;

  /// No description provided for @statusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get statusAll;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @searchMerchantOrProductHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a merchant or product'**
  String get searchMerchantOrProductHint;

  /// No description provided for @filterByStatusHint.
  ///
  /// In en, this message translates to:
  /// **'Filter by status'**
  String get filterByStatusHint;

  /// No description provided for @packageLabel.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get packageLabel;

  /// No description provided for @productLabel.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get productLabel;

  /// No description provided for @revisionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Revisions'**
  String get revisionsLabel;

  /// No description provided for @acceptBtn.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptBtn;

  /// No description provided for @rejectBtn.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectBtn;

  /// No description provided for @requestAcceptedSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Request accepted'**
  String get requestAcceptedSuccessMsg;

  /// No description provided for @startExecutionBtn.
  ///
  /// In en, this message translates to:
  /// **'Start Execution'**
  String get startExecutionBtn;

  /// No description provided for @projectStartedSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Project started'**
  String get projectStartedSuccessMsg;

  /// No description provided for @deliverWorkBtn.
  ///
  /// In en, this message translates to:
  /// **'Deliver Work'**
  String get deliverWorkBtn;

  /// No description provided for @workDeliveredSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Work delivered'**
  String get workDeliveredSuccessMsg;

  /// No description provided for @waitingForMerchantApprovalMsg.
  ///
  /// In en, this message translates to:
  /// **'Waiting for merchant approval'**
  String get waitingForMerchantApprovalMsg;

  /// No description provided for @noRequestsMsg.
  ///
  /// In en, this message translates to:
  /// **'No requests'**
  String get noRequestsMsg;

  /// No description provided for @noCollabRequestsYetMsg.
  ///
  /// In en, this message translates to:
  /// **'You have not received any collaboration requests yet'**
  String get noCollabRequestsYetMsg;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// No description provided for @newStoryBtn.
  ///
  /// In en, this message translates to:
  /// **'New Story'**
  String get newStoryBtn;

  /// No description provided for @activeStoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Stories'**
  String get activeStoriesTitle;

  /// No description provided for @noActiveStoriesMsg.
  ///
  /// In en, this message translates to:
  /// **'No active stories currently'**
  String get noActiveStoriesMsg;

  /// No description provided for @deleteStoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Story'**
  String get deleteStoryTitle;

  /// No description provided for @deleteStoryConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? The story will be permanently deleted.'**
  String get deleteStoryConfirmMsg;

  /// No description provided for @imageType.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get imageType;

  /// No description provided for @videoType.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoType;

  /// No description provided for @textType.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textType;

  /// No description provided for @productType.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get productType;

  /// No description provided for @pleaseSelectFileMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select a file'**
  String get pleaseSelectFileMsg;

  /// No description provided for @pleaseWriteTextMsg.
  ///
  /// In en, this message translates to:
  /// **'Please write text'**
  String get pleaseWriteTextMsg;

  /// No description provided for @pleaseSelectProductMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select a product'**
  String get pleaseSelectProductMsg;

  /// No description provided for @storyPublishedSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Story published successfully 🎉'**
  String get storyPublishedSuccessMsg;

  /// No description provided for @addNewStoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Story'**
  String get addNewStoryTitle;

  /// No description provided for @publishStoryBtn.
  ///
  /// In en, this message translates to:
  /// **'Publish Story'**
  String get publishStoryBtn;

  /// No description provided for @tapToUploadMsg.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload '**
  String get tapToUploadMsg;

  /// No description provided for @addStoryCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a caption (optional)...'**
  String get addStoryCaptionHint;

  /// No description provided for @writeYourStoryHereHint.
  ///
  /// In en, this message translates to:
  /// **'Write your story here...'**
  String get writeYourStoryHereHint;

  /// No description provided for @noProductsToPromoteMsg.
  ///
  /// In en, this message translates to:
  /// **'No products available to promote'**
  String get noProductsToPromoteMsg;

  /// No description provided for @chooseProductToPromoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose a product to promote'**
  String get chooseProductToPromoteLabel;

  /// No description provided for @defaultProductLabel.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get defaultProductLabel;

  /// No description provided for @chooseProductForPreviewMsg.
  ///
  /// In en, this message translates to:
  /// **'Choose a product to preview'**
  String get chooseProductForPreviewMsg;

  /// No description provided for @monthlyRange.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyRange;

  /// No description provided for @quarterlyRange.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get quarterlyRange;

  /// No description provided for @yearlyRange.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearlyRange;

  /// No description provided for @totalEarningsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarningsLabel;

  /// No description provided for @completedAgreementsLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed Agreements'**
  String get completedAgreementsLabel;

  /// No description provided for @averageDealPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Average Deal'**
  String get averageDealPriceLabel;

  /// No description provided for @engagementRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Engagement'**
  String get engagementRateLabel;

  /// No description provided for @requestsOverTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Requests Over Time'**
  String get requestsOverTimeTitle;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @analyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your account performance and earnings'**
  String get analyticsSubtitle;

  /// No description provided for @topOffersTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Offers'**
  String get topOffersTitle;

  /// No description provided for @performanceInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance Insights'**
  String get performanceInsightsTitle;

  /// No description provided for @profileViewsLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile Views'**
  String get profileViewsLabel;

  /// No description provided for @completionRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get completionRateLabel;

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Wallet'**
  String get walletTitle;

  /// No description provided for @enterValidAmountMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get enterValidAmountMsg;

  /// No description provided for @insufficientBalanceMsg.
  ///
  /// In en, this message translates to:
  /// **'Insufficient available balance'**
  String get insufficientBalanceMsg;

  /// No description provided for @minPayoutMsg.
  ///
  /// In en, this message translates to:
  /// **'Minimum payout is 50 '**
  String get minPayoutMsg;

  /// No description provided for @saleEarningType.
  ///
  /// In en, this message translates to:
  /// **'Sale Earning'**
  String get saleEarningType;

  /// No description provided for @shippingEarningType.
  ///
  /// In en, this message translates to:
  /// **'Shipping Earning'**
  String get shippingEarningType;

  /// No description provided for @codCommissionDeductionType.
  ///
  /// In en, this message translates to:
  /// **'Commission (COD)'**
  String get codCommissionDeductionType;

  /// No description provided for @commissionDeductionType.
  ///
  /// In en, this message translates to:
  /// **'Commission Deduction'**
  String get commissionDeductionType;

  /// No description provided for @payoutType.
  ///
  /// In en, this message translates to:
  /// **'Payout'**
  String get payoutType;

  /// No description provided for @agreementIncomeType.
  ///
  /// In en, this message translates to:
  /// **'Marketing Earning'**
  String get agreementIncomeType;

  /// No description provided for @adjustmentType.
  ///
  /// In en, this message translates to:
  /// **'Administrative Adjustment'**
  String get adjustmentType;

  /// No description provided for @availableToWithdrawLabel.
  ///
  /// In en, this message translates to:
  /// **'Available to Withdraw'**
  String get availableToWithdrawLabel;

  /// No description provided for @readyToTransferLabel.
  ///
  /// In en, this message translates to:
  /// **'Ready to transfer'**
  String get readyToTransferLabel;

  /// No description provided for @debtsLabel.
  ///
  /// In en, this message translates to:
  /// **'Debts'**
  String get debtsLabel;

  /// No description provided for @autoDeductedLabel.
  ///
  /// In en, this message translates to:
  /// **'Deducted automatically'**
  String get autoDeductedLabel;

  /// No description provided for @noDebtsLabel.
  ///
  /// In en, this message translates to:
  /// **'No debts'**
  String get noDebtsLabel;

  /// No description provided for @pendingSettlementLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending Settlement'**
  String get pendingSettlementLabel;

  /// No description provided for @operationsLabel.
  ///
  /// In en, this message translates to:
  /// **'operations'**
  String get operationsLabel;

  /// No description provided for @totalProfitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalProfitsLabel;

  /// No description provided for @historicalLabel.
  ///
  /// In en, this message translates to:
  /// **'Historical'**
  String get historicalLabel;

  /// No description provided for @requestPayoutBtn.
  ///
  /// In en, this message translates to:
  /// **'Request Payout'**
  String get requestPayoutBtn;

  /// No description provided for @allTab.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allTab;

  /// No description provided for @depositTab.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get depositTab;

  /// No description provided for @deductionTab.
  ///
  /// In en, this message translates to:
  /// **'Deduction'**
  String get deductionTab;

  /// No description provided for @withdrawTab.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdrawTab;

  /// No description provided for @noOperationsMsg.
  ///
  /// In en, this message translates to:
  /// **'No operations'**
  String get noOperationsMsg;

  /// No description provided for @completedStatus.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedStatus;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @processingStatus.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processingStatus;

  /// No description provided for @cancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledStatus;

  /// No description provided for @payoutRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Payout Request'**
  String get payoutRequestTitle;

  /// No description provided for @availableBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalanceLabel;

  /// No description provided for @requestedAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Requested Amount'**
  String get requestedAmountLabel;

  /// No description provided for @confirmWithdrawalBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm Withdraw'**
  String get confirmWithdrawalBtn;

  /// No description provided for @conversationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversationsTitle;

  /// No description provided for @attachmentMsg.
  ///
  /// In en, this message translates to:
  /// **'Attachment 📎'**
  String get attachmentMsg;

  /// No description provided for @startNewConversationMsg.
  ///
  /// In en, this message translates to:
  /// **'Start a new conversation'**
  String get startNewConversationMsg;

  /// No description provided for @onlineNow.
  ///
  /// In en, this message translates to:
  /// **'Online now'**
  String get onlineNow;

  /// No description provided for @lastSeenPrefix.
  ///
  /// In en, this message translates to:
  /// **'Last seen '**
  String get lastSeenPrefix;

  /// No description provided for @offlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineStatus;

  /// No description provided for @typeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessageHint;

  /// No description provided for @certificateUploadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Certificate uploaded successfully ✅'**
  String get certificateUploadedSuccess;

  /// No description provided for @fileUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload file'**
  String get fileUploadFailed;

  /// No description provided for @pleaseUploadIbanCertificate.
  ///
  /// In en, this message translates to:
  /// **'Please upload IBAN certificate'**
  String get pleaseUploadIbanCertificate;

  /// No description provided for @dataSavedUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Data saved and sent for review ✅'**
  String get dataSavedUnderReview;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get saveFailed;

  /// No description provided for @accountUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Account Under Review'**
  String get accountUnderReview;

  /// No description provided for @accountUnderReviewDesc.
  ///
  /// In en, this message translates to:
  /// **'Your bank details are being reviewed, the account will be activated soon.'**
  String get accountUnderReviewDesc;

  /// No description provided for @dataRejected.
  ///
  /// In en, this message translates to:
  /// **'Data Rejected'**
  String get dataRejected;

  /// No description provided for @pleaseReviewAndRetry.
  ///
  /// In en, this message translates to:
  /// **'Please review your data and try again.'**
  String get pleaseReviewAndRetry;

  /// No description provided for @accountActivated.
  ///
  /// In en, this message translates to:
  /// **'Account Activated'**
  String get accountActivated;

  /// No description provided for @bankDetailsVerified.
  ///
  /// In en, this message translates to:
  /// **'Your bank details have been verified successfully.'**
  String get bankDetailsVerified;

  /// No description provided for @bankName.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get bankName;

  /// No description provided for @bankNameHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Al Rajhi Bank'**
  String get bankNameHint;

  /// No description provided for @accountHolderName.
  ///
  /// In en, this message translates to:
  /// **'Account Holder Name'**
  String get accountHolderName;

  /// No description provided for @accountHolderNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full name as on ID'**
  String get accountHolderNameHint;

  /// No description provided for @ibanNumber.
  ///
  /// In en, this message translates to:
  /// **'IBAN Number'**
  String get ibanNumber;

  /// No description provided for @ibanCondition.
  ///
  /// In en, this message translates to:
  /// **'Must start with SA and consist of 24 characters.'**
  String get ibanCondition;

  /// No description provided for @accountNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Account Number (Optional)'**
  String get accountNumberOptional;

  /// No description provided for @localAccountNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Local account number'**
  String get localAccountNumberHint;

  /// No description provided for @ibanCertificate.
  ///
  /// In en, this message translates to:
  /// **'IBAN Certificate'**
  String get ibanCertificate;

  /// No description provided for @fileUploadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'File uploaded successfully'**
  String get fileUploadedSuccess;

  /// No description provided for @clickToReplace.
  ///
  /// In en, this message translates to:
  /// **'Click to replace'**
  String get clickToReplace;

  /// No description provided for @clickToUpload.
  ///
  /// In en, this message translates to:
  /// **'Click to upload'**
  String get clickToUpload;

  /// No description provided for @clearIbanImage.
  ///
  /// In en, this message translates to:
  /// **'Clear image of IBAN certificate'**
  String get clearIbanImage;

  /// No description provided for @bankDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank Details'**
  String get bankDetailsTitle;

  /// No description provided for @manageBankAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your bank account to receive earnings and payments.'**
  String get manageBankAccountDesc;

  /// No description provided for @optionalWord.
  ///
  /// In en, this message translates to:
  /// **'(Optional)'**
  String get optionalWord;

  /// No description provided for @imageUploadedSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded successfully'**
  String get imageUploadedSuccessMsg;

  /// No description provided for @uploadFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadFailedMsg;

  /// No description provided for @addCoverPhotoMsg.
  ///
  /// In en, this message translates to:
  /// **'Add cover photo'**
  String get addCoverPhotoMsg;

  /// No description provided for @portfolioTitle.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolioTitle;

  /// No description provided for @autoStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stats (Auto)'**
  String get autoStatsTitle;

  /// No description provided for @totalFollowersLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Followers'**
  String get totalFollowersLabel;

  /// No description provided for @socialLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Social Links'**
  String get socialLinksTitle;

  /// No description provided for @updateInfoToAttractClientsMsg.
  ///
  /// In en, this message translates to:
  /// **'Update your information to attract more clients'**
  String get updateInfoToAttractClientsMsg;

  /// No description provided for @bioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bioLabel;

  /// No description provided for @mySubscription.
  ///
  /// In en, this message translates to:
  /// **'My Subscription'**
  String get mySubscription;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @offersTab.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offersTab;

  /// No description provided for @requestsTab.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requestsTab;

  /// No description provided for @featureLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Feature Locked'**
  String get featureLockedTitle;

  /// No description provided for @featureLockedModelDescPart1.
  ///
  /// In en, this message translates to:
  /// **'Sorry, the ('**
  String get featureLockedModelDescPart1;

  /// No description provided for @featureLockedModelDescPart2.
  ///
  /// In en, this message translates to:
  /// **') feature is only available for premium package subscribers.'**
  String get featureLockedModelDescPart2;

  /// No description provided for @defaultModelName.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get defaultModelName;

  /// No description provided for @welcomeHello.
  ///
  /// In en, this message translates to:
  /// **'Hello, '**
  String get welcomeHello;

  /// No description provided for @performanceSummaryMsg.
  ///
  /// In en, this message translates to:
  /// **'Here is your account performance summary for today.'**
  String get performanceSummaryMsg;

  /// No description provided for @agreementsLabel.
  ///
  /// In en, this message translates to:
  /// **'Agreements'**
  String get agreementsLabel;

  /// No description provided for @performanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performanceLabel;

  /// No description provided for @orderCompletionRate.
  ///
  /// In en, this message translates to:
  /// **'Order Completion'**
  String get orderCompletionRate;

  /// No description provided for @failedToUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update status'**
  String get failedToUpdateStatus;

  /// No description provided for @markAllAsReadBtn.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsReadBtn;

  /// No description provided for @noNewNotificationsMsg.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get noNewNotificationsMsg;

  /// No description provided for @subscribeNow.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscribeNow;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @productsManagement.
  ///
  /// In en, this message translates to:
  /// **'Products Management'**
  String get productsManagement;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @storePreview.
  ///
  /// In en, this message translates to:
  /// **'Store Preview'**
  String get storePreview;

  /// No description provided for @storeStories.
  ///
  /// In en, this message translates to:
  /// **'Store Stories'**
  String get storeStories;

  /// No description provided for @modelsAndInfluencers.
  ///
  /// In en, this message translates to:
  /// **'Models & Influencers'**
  String get modelsAndInfluencers;

  /// No description provided for @bankInfo.
  ///
  /// In en, this message translates to:
  /// **'Bank Information'**
  String get bankInfo;

  /// No description provided for @dropshipping.
  ///
  /// In en, this message translates to:
  /// **'Dropshipping'**
  String get dropshipping;

  /// No description provided for @shipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get shipping;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @featureRequiresSubscriptionMsg.
  ///
  /// In en, this message translates to:
  /// **'Sorry, the feature ({featureName}) requires an active subscription to access.'**
  String featureRequiresSubscriptionMsg(String featureName);

  /// No description provided for @fromTotalReviews.
  ///
  /// In en, this message translates to:
  /// **'from {count} reviews'**
  String fromTotalReviews(String count);

  /// No description provided for @salesAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Sales Analysis'**
  String get salesAnalysis;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @verificationRejected.
  ///
  /// In en, this message translates to:
  /// **'Verification Rejected'**
  String get verificationRejected;

  /// No description provided for @verificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Verification Required'**
  String get verificationRequired;

  /// No description provided for @pleaseCompleteVerification.
  ///
  /// In en, this message translates to:
  /// **'Please complete merchant verification details to start selling.'**
  String get pleaseCompleteVerification;

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReview;

  /// No description provided for @dataUnderReviewMsg.
  ///
  /// In en, this message translates to:
  /// **'Your data is being reviewed, your account will be activated soon.'**
  String get dataUnderReviewMsg;

  /// No description provided for @startVerification.
  ///
  /// In en, this message translates to:
  /// **'Start Verification'**
  String get startVerification;

  /// No description provided for @storePerformanceToday.
  ///
  /// In en, this message translates to:
  /// **'Here is a quick look at your store\'s performance today.'**
  String get storePerformanceToday;

  /// No description provided for @totalSales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get totalSales;

  /// No description provided for @newOrders.
  ///
  /// In en, this message translates to:
  /// **'New Orders'**
  String get newOrders;

  /// No description provided for @activeProducts.
  ///
  /// In en, this message translates to:
  /// **'Active Products'**
  String get activeProducts;

  /// No description provided for @overallRating.
  ///
  /// In en, this message translates to:
  /// **'Overall Rating'**
  String get overallRating;

  /// No description provided for @monthlyViews.
  ///
  /// In en, this message translates to:
  /// **'Monthly Views'**
  String get monthlyViews;

  /// No description provided for @ordersManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders Management'**
  String get ordersManagementTitle;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @profits.
  ///
  /// In en, this message translates to:
  /// **'Profits'**
  String get profits;

  /// No description provided for @searchOrderOrCustomerHint.
  ///
  /// In en, this message translates to:
  /// **'Search by order number or customer name...'**
  String get searchOrderOrCustomerHint;

  /// No description provided for @noMatchingOrdersMsg.
  ///
  /// In en, this message translates to:
  /// **'No matching orders found'**
  String get noMatchingOrdersMsg;

  /// No description provided for @viewDetailsBtn.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetailsBtn;

  /// No description provided for @shipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get shipped;

  /// No description provided for @processingOrder.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processingOrder;

  /// No description provided for @changeOrderStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Order Status'**
  String get changeOrderStatusTitle;

  /// No description provided for @confirmChangeStatusPrefix.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to change the status to '**
  String get confirmChangeStatusPrefix;

  /// No description provided for @confirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmBtn;

  /// No description provided for @statusUpdatedSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Status updated successfully ✅'**
  String get statusUpdatedSuccessMsg;

  /// No description provided for @notAllowedToEditDropshippingOrderMsg.
  ///
  /// In en, this message translates to:
  /// **'Not allowed to edit this order (Dropshipping)'**
  String get notAllowedToEditDropshippingOrderMsg;

  /// No description provided for @copiedToClipboardMsg.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboardMsg;

  /// No description provided for @orderHashPrefix.
  ///
  /// In en, this message translates to:
  /// **'Order #'**
  String get orderHashPrefix;

  /// No description provided for @orderDatePrefix.
  ///
  /// In en, this message translates to:
  /// **'Order Date: '**
  String get orderDatePrefix;

  /// No description provided for @updateStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Update Status:'**
  String get updateStatusLabel;

  /// No description provided for @customerInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer Info'**
  String get customerInfoLabel;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @productsLabelWithCountPrefix.
  ///
  /// In en, this message translates to:
  /// **'Products ('**
  String get productsLabelWithCountPrefix;

  /// No description provided for @productsLabelWithCountSuffix.
  ///
  /// In en, this message translates to:
  /// **')'**
  String get productsLabelWithCountSuffix;

  /// No description provided for @quantityPrefix.
  ///
  /// In en, this message translates to:
  /// **'Quantity: '**
  String get quantityPrefix;

  /// No description provided for @shippingAndPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Shipping & Payment'**
  String get shippingAndPaymentLabel;

  /// No description provided for @shippingAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Shipping Address'**
  String get shippingAddressLabel;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethodLabel;

  /// No description provided for @paymentStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatusLabel;

  /// No description provided for @paidStatus.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidStatus;

  /// No description provided for @unpaidStatus.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaidStatus;

  /// No description provided for @copyBtn.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyBtn;

  /// No description provided for @failedToLoadStoreDataMsg.
  ///
  /// In en, this message translates to:
  /// **'Failed to load store data'**
  String get failedToLoadStoreDataMsg;

  /// No description provided for @noStoreDataMsg.
  ///
  /// In en, this message translates to:
  /// **'No store data available'**
  String get noStoreDataMsg;

  /// No description provided for @newProductBtn.
  ///
  /// In en, this message translates to:
  /// **'New Product'**
  String get newProductBtn;

  /// No description provided for @trustedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get trustedBadge;

  /// No description provided for @dropshipperBadge.
  ///
  /// In en, this message translates to:
  /// **'Dropshipper'**
  String get dropshipperBadge;

  /// No description provided for @editStoreBtn.
  ///
  /// In en, this message translates to:
  /// **'Edit Store'**
  String get editStoreBtn;

  /// No description provided for @previewAsVisitorBtn.
  ///
  /// In en, this message translates to:
  /// **'Preview as Visitor'**
  String get previewAsVisitorBtn;

  /// No description provided for @salesLabel.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get salesLabel;

  /// No description provided for @followersLabel.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followersLabel;

  /// No description provided for @myProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Products'**
  String get myProductsTitle;

  /// No description provided for @noProductsYetMsg.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get noProductsYetMsg;

  /// No description provided for @remainingStockPrefix.
  ///
  /// In en, this message translates to:
  /// **'Left: '**
  String get remainingStockPrefix;

  /// No description provided for @deleteStoryConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this story?\nIt will be permanently removed and clients will not be able to see it.'**
  String get deleteStoryConfirmDesc;

  /// No description provided for @storyDeletedSuccessfullyMsg.
  ///
  /// In en, this message translates to:
  /// **'Story deleted successfully'**
  String get storyDeletedSuccessfullyMsg;

  /// No description provided for @failedToDeleteStoryMsg.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete story'**
  String get failedToDeleteStoryMsg;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// No description provided for @shareMomentsWithClientsMsg.
  ///
  /// In en, this message translates to:
  /// **'Share your products and moments with your clients now'**
  String get shareMomentsWithClientsMsg;

  /// No description provided for @failedToPickFileMsg.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick file'**
  String get failedToPickFileMsg;

  /// No description provided for @pleaseWriteStoryTextMsg.
  ///
  /// In en, this message translates to:
  /// **'Please write a text for the story'**
  String get pleaseWriteStoryTextMsg;

  /// No description provided for @publishedSuccessfullyMsg.
  ///
  /// In en, this message translates to:
  /// **'Published successfully! 🎉'**
  String get publishedSuccessfullyMsg;

  /// No description provided for @errorPublishingMsg.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while publishing: '**
  String get errorPublishingMsg;

  /// No description provided for @shareYourSpecialMomentsMsg.
  ///
  /// In en, this message translates to:
  /// **'Share your special moments'**
  String get shareYourSpecialMomentsMsg;

  /// No description provided for @tapToSelectImageMsg.
  ///
  /// In en, this message translates to:
  /// **'Tap to select an image'**
  String get tapToSelectImageMsg;

  /// No description provided for @tapToSelectVideoMsg.
  ///
  /// In en, this message translates to:
  /// **'Tap to select a video'**
  String get tapToSelectVideoMsg;

  /// No description provided for @supportedMediaFormatsMsg.
  ///
  /// In en, this message translates to:
  /// **'Supports PNG, JPG, MP4'**
  String get supportedMediaFormatsMsg;

  /// No description provided for @addCaptionOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Add a caption (optional)...'**
  String get addCaptionOptionalHint;

  /// No description provided for @textContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Text Content'**
  String get textContentLabel;

  /// No description provided for @backgroundColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get backgroundColorLabel;

  /// No description provided for @previewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewLabel;

  /// No description provided for @yourTextWillAppearHereMsg.
  ///
  /// In en, this message translates to:
  /// **'Your text will appear here...'**
  String get yourTextWillAppearHereMsg;

  /// No description provided for @searchNameOrSpecialtyHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or specialty...'**
  String get searchNameOrSpecialtyHint;

  /// No description provided for @allCategory.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategory;

  /// No description provided for @featuredBadge.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featuredBadge;

  /// No description provided for @fashionModelRole.
  ///
  /// In en, this message translates to:
  /// **'Fashion Model'**
  String get fashionModelRole;

  /// No description provided for @contentCreatorRole.
  ///
  /// In en, this message translates to:
  /// **'Content Creator'**
  String get contentCreatorRole;

  /// No description provided for @noResultsFoundMsg.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFoundMsg;

  /// No description provided for @sortResultsByTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort results by'**
  String get sortResultsByTitle;

  /// No description provided for @highestRatedSort.
  ///
  /// In en, this message translates to:
  /// **'Highest Rated'**
  String get highestRatedSort;

  /// No description provided for @mostFollowedSort.
  ///
  /// In en, this message translates to:
  /// **'Most Followed'**
  String get mostFollowedSort;

  /// No description provided for @nameAZSort.
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get nameAZSort;

  /// No description provided for @linkNotAvailableMsg.
  ///
  /// In en, this message translates to:
  /// **'Link not available'**
  String get linkNotAvailableMsg;

  /// No description provided for @couldNotOpenLinkMsg.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link'**
  String get couldNotOpenLinkMsg;

  /// No description provided for @errorOpeningLinkMsg.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while opening the link'**
  String get errorOpeningLinkMsg;

  /// No description provided for @loginRequiredMsg.
  ///
  /// In en, this message translates to:
  /// **'You must login first'**
  String get loginRequiredMsg;

  /// No description provided for @errorTryAgainMsg.
  ///
  /// In en, this message translates to:
  /// **'An error occurred, please try again'**
  String get errorTryAgainMsg;

  /// No description provided for @mustHaveProductsToOrderMsg.
  ///
  /// In en, this message translates to:
  /// **'You must have products to place an order'**
  String get mustHaveProductsToOrderMsg;

  /// No description provided for @orderSentSuccessfullyMsg.
  ///
  /// In en, this message translates to:
  /// **'✅ Order sent successfully!'**
  String get orderSentSuccessfullyMsg;

  /// No description provided for @notFoundMsg.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFoundMsg;

  /// No description provided for @galleryTab.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryTab;

  /// No description provided for @packagesTab.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get packagesTab;

  /// No description provided for @ratingStat.
  ///
  /// In en, this message translates to:
  /// **'Rating ⭐'**
  String get ratingStat;

  /// No description provided for @engagementStat.
  ///
  /// In en, this message translates to:
  /// **'Engagement'**
  String get engagementStat;

  /// No description provided for @noImagesInGalleryMsg.
  ///
  /// In en, this message translates to:
  /// **'No images in the gallery'**
  String get noImagesInGalleryMsg;

  /// No description provided for @noPackagesMsg.
  ///
  /// In en, this message translates to:
  /// **'No packages'**
  String get noPackagesMsg;

  /// No description provided for @choosePackageBtn.
  ///
  /// In en, this message translates to:
  /// **'Choose Package'**
  String get choosePackageBtn;

  /// No description provided for @requestOfferBtn.
  ///
  /// In en, this message translates to:
  /// **'Request Offer'**
  String get requestOfferBtn;

  /// No description provided for @chatBtn.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatBtn;

  /// No description provided for @selectProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a product'**
  String get selectProductTitle;

  /// No description provided for @myAgreementsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Agreements'**
  String get myAgreementsTitle;

  /// No description provided for @searchModelOrPackageHint.
  ///
  /// In en, this message translates to:
  /// **'Search by model name or package...'**
  String get searchModelOrPackageHint;

  /// No description provided for @noAgreementsMsg.
  ///
  /// In en, this message translates to:
  /// **'No agreements'**
  String get noAgreementsMsg;

  /// No description provided for @confirmReceiptBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm Receipt'**
  String get confirmReceiptBtn;

  /// No description provided for @receiptConfirmedSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Receipt confirmed successfully ✅'**
  String get receiptConfirmedSuccessMsg;

  /// No description provided for @addReviewBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Review'**
  String get addReviewBtn;

  /// No description provided for @rateYourExperienceTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate your experience'**
  String get rateYourExperienceTitle;

  /// No description provided for @withModelPrefix.
  ///
  /// In en, this message translates to:
  /// **'with '**
  String get withModelPrefix;

  /// No description provided for @writeCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Write your comment here...'**
  String get writeCommentHint;

  /// No description provided for @confirmRatingBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm Rating'**
  String get confirmRatingBtn;

  /// No description provided for @ratingSentSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Rating sent successfully ⭐'**
  String get ratingSentSuccessMsg;

  /// No description provided for @reviewedBadge.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get reviewedBadge;

  /// No description provided for @bankAccountDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank Account Details'**
  String get bankAccountDetailsTitle;

  /// No description provided for @accountVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Verified'**
  String get accountVerifiedTitle;

  /// No description provided for @accountVerifiedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your bank details are verified and ready to receive transfers.'**
  String get accountVerifiedDesc;

  /// No description provided for @dataRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Rejected'**
  String get dataRejectedTitle;

  /// No description provided for @reasonPrefix.
  ///
  /// In en, this message translates to:
  /// **'Reason: '**
  String get reasonPrefix;

  /// No description provided for @pleaseEnsureCorrectDataMsg.
  ///
  /// In en, this message translates to:
  /// **'Please ensure the data is correct and the certificate is clear.'**
  String get pleaseEnsureCorrectDataMsg;

  /// No description provided for @underReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReviewTitle;

  /// No description provided for @bankDataUnderReviewDesc.
  ///
  /// In en, this message translates to:
  /// **'Your bank details are being reviewed by the administration.'**
  String get bankDataUnderReviewDesc;

  /// No description provided for @enterDataAsInCertificateMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter the data exactly as it appears on the IBAN certificate'**
  String get enterDataAsInCertificateMsg;

  /// No description provided for @pleaseUploadClearIbanImageMsg.
  ///
  /// In en, this message translates to:
  /// **'Please upload a clear image of the IBAN certificate'**
  String get pleaseUploadClearIbanImageMsg;

  /// No description provided for @uploadingMsg.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploadingMsg;

  /// No description provided for @fileUploadedMsg.
  ///
  /// In en, this message translates to:
  /// **'File Uploaded'**
  String get fileUploadedMsg;

  /// No description provided for @supportedImageFormatsMsg.
  ///
  /// In en, this message translates to:
  /// **'PNG, JPG (Max 5MB)'**
  String get supportedImageFormatsMsg;

  /// No description provided for @savingMsg.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingMsg;

  /// No description provided for @saveDataBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Data'**
  String get saveDataBtn;

  /// No description provided for @thisFieldIsRequiredMsg.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get thisFieldIsRequiredMsg;

  /// No description provided for @failedToLoadProductsMsg.
  ///
  /// In en, this message translates to:
  /// **'Failed to load products'**
  String get failedToLoadProductsMsg;

  /// No description provided for @productAddedSuccessfullyMsg.
  ///
  /// In en, this message translates to:
  /// **'✅ Product added to your store successfully!'**
  String get productAddedSuccessfullyMsg;

  /// No description provided for @importFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'❌ Import failed'**
  String get importFailedMsg;

  /// No description provided for @productAlreadyExistsMsg.
  ///
  /// In en, this message translates to:
  /// **'⚠️ This product is already in your store!'**
  String get productAlreadyExistsMsg;

  /// No description provided for @exclusiveContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Exclusive Content'**
  String get exclusiveContentTitle;

  /// No description provided for @exclusiveDropshippingDesc.
  ///
  /// In en, this message translates to:
  /// **'This feature is only available to dropshipping subscribers. Upgrade to access thousands of ready-to-sell products.'**
  String get exclusiveDropshippingDesc;

  /// No description provided for @dropshippingMarketTitle.
  ///
  /// In en, this message translates to:
  /// **'Dropshipping Market'**
  String get dropshippingMarketTitle;

  /// No description provided for @exploreThousandsProductsDesc.
  ///
  /// In en, this message translates to:
  /// **'Explore thousands of products and add them to your store with one click'**
  String get exploreThousandsProductsDesc;

  /// No description provided for @totalProducts.
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get totalProducts;

  /// No description provided for @featuredProducts.
  ///
  /// In en, this message translates to:
  /// **'Featured Products'**
  String get featuredProducts;

  /// No description provided for @suppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliers;

  /// No description provided for @searchProductHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a product...'**
  String get searchProductHint;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @featuredBadgeText.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featuredBadgeText;

  /// No description provided for @supplierPrefix.
  ///
  /// In en, this message translates to:
  /// **'Supplier: '**
  String get supplierPrefix;

  /// No description provided for @addToStoreBtn.
  ///
  /// In en, this message translates to:
  /// **'Add to Store'**
  String get addToStoreBtn;

  /// No description provided for @failedToLoadDataMsg.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data'**
  String get failedToLoadDataMsg;

  /// No description provided for @dataUpdatedSuccessfullyMsg.
  ///
  /// In en, this message translates to:
  /// **'Data updated successfully'**
  String get dataUpdatedSuccessfullyMsg;

  /// No description provided for @companyAddedSuccessfullyMsg.
  ///
  /// In en, this message translates to:
  /// **'Company added successfully'**
  String get companyAddedSuccessfullyMsg;

  /// No description provided for @errorWhileSavingMsg.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while saving'**
  String get errorWhileSavingMsg;

  /// No description provided for @companyDisabledMsg.
  ///
  /// In en, this message translates to:
  /// **'Company disabled'**
  String get companyDisabledMsg;

  /// No description provided for @companyEnabledMsg.
  ///
  /// In en, this message translates to:
  /// **'Company enabled'**
  String get companyEnabledMsg;

  /// No description provided for @statusChangeFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Failed to change status'**
  String get statusChangeFailedMsg;

  /// No description provided for @addNewCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Company'**
  String get addNewCompanyTitle;

  /// No description provided for @editDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Data'**
  String get editDataTitle;

  /// No description provided for @companyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyNameLabel;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @deliveryTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Time (e.g., 3-5 days)'**
  String get deliveryTimeLabel;

  /// No description provided for @confirmDeletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletionTitle;

  /// No description provided for @confirmDeleteCompanyDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete company \'{companyName}\'?'**
  String confirmDeleteCompanyDesc(String companyName);

  /// No description provided for @searchBtn.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchBtn;

  /// No description provided for @backBtn.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backBtn;

  /// No description provided for @totalStat.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalStat;

  /// No description provided for @activeStat.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStat;

  /// No description provided for @averagePriceStat.
  ///
  /// In en, this message translates to:
  /// **'Avg Price'**
  String get averagePriceStat;

  /// No description provided for @totalCostStat.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get totalCostStat;

  /// No description provided for @shippingManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Shipping Management'**
  String get shippingManagementTitle;

  /// No description provided for @manageShippingCompaniesDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage shipping and delivery companies and set prices'**
  String get manageShippingCompaniesDesc;

  /// No description provided for @addedOnPrefix.
  ///
  /// In en, this message translates to:
  /// **'Added on: '**
  String get addedOnPrefix;

  /// No description provided for @noShippingCompaniesMsg.
  ///
  /// In en, this message translates to:
  /// **'No shipping companies'**
  String get noShippingCompaniesMsg;

  /// No description provided for @trySearchingOtherWordMsg.
  ///
  /// In en, this message translates to:
  /// **'Try searching with another word'**
  String get trySearchingOtherWordMsg;

  /// No description provided for @generalTab.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalTab;

  /// No description provided for @storeTab.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get storeTab;

  /// No description provided for @socialTab.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get socialTab;

  /// No description provided for @notificationsTab.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTab;

  /// No description provided for @privacyTab.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTab;

  /// No description provided for @subscriptionTab.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionTab;

  /// No description provided for @changesSavedSuccessfullyMsg.
  ///
  /// In en, this message translates to:
  /// **'Changes saved successfully'**
  String get changesSavedSuccessfullyMsg;

  /// No description provided for @confirmCancellationTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cancellation'**
  String get confirmCancellationTitle;

  /// No description provided for @confirmCancelSubscriptionMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel the subscription?'**
  String get confirmCancelSubscriptionMsg;

  /// No description provided for @subscriptionCancelledMsg.
  ///
  /// In en, this message translates to:
  /// **'Subscription cancelled'**
  String get subscriptionCancelledMsg;

  /// No description provided for @failedToCancelSubscriptionMsg.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel subscription'**
  String get failedToCancelSubscriptionMsg;

  /// No description provided for @generalSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettingsTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @storeDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Store Details'**
  String get storeDetailsTitle;

  /// No description provided for @storeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Store Name'**
  String get storeNameLabel;

  /// No description provided for @storeDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Store Description'**
  String get storeDescriptionLabel;

  /// No description provided for @storeLogoHint.
  ///
  /// In en, this message translates to:
  /// **'Store Image (Logo). Preferably square.'**
  String get storeLogoHint;

  /// No description provided for @storeBannerLabel.
  ///
  /// In en, this message translates to:
  /// **'Store Banner'**
  String get storeBannerLabel;

  /// No description provided for @tapToUploadBannerMsg.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload banner'**
  String get tapToUploadBannerMsg;

  /// No description provided for @socialMediaLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Social Media Links'**
  String get socialMediaLinksTitle;

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettingsTitle;

  /// No description provided for @receiveEmailUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive updates via email'**
  String get receiveEmailUpdatesDesc;

  /// No description provided for @appNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'App Notifications'**
  String get appNotificationsLabel;

  /// No description provided for @receivePushNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive push notifications'**
  String get receivePushNotificationsDesc;

  /// No description provided for @smsMessagesLabel.
  ///
  /// In en, this message translates to:
  /// **'SMS Messages'**
  String get smsMessagesLabel;

  /// No description provided for @receiveSmsUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive updates via text messages'**
  String get receiveSmsUpdatesDesc;

  /// No description provided for @showEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Show Email'**
  String get showEmailLabel;

  /// No description provided for @showEmailDesc.
  ///
  /// In en, this message translates to:
  /// **'Display email on public store page'**
  String get showEmailDesc;

  /// No description provided for @showPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Show Phone Number'**
  String get showPhoneLabel;

  /// No description provided for @showPhoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Display phone number to customers'**
  String get showPhoneDesc;

  /// No description provided for @perMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get perMonthLabel;

  /// No description provided for @startPrefix.
  ///
  /// In en, this message translates to:
  /// **'Start: '**
  String get startPrefix;

  /// No description provided for @endPrefix.
  ///
  /// In en, this message translates to:
  /// **'End: '**
  String get endPrefix;

  /// No description provided for @cancelSubscriptionBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription'**
  String get cancelSubscriptionBtn;

  /// No description provided for @subscriptionHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription History'**
  String get subscriptionHistoryTitle;

  /// No description provided for @noActiveSubscriptionMsg.
  ///
  /// In en, this message translates to:
  /// **'No active subscription'**
  String get noActiveSubscriptionMsg;

  /// No description provided for @supplierRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplierRoleLabel;

  /// No description provided for @incomingOrders.
  ///
  /// In en, this message translates to:
  /// **'Incoming Orders'**
  String get incomingOrders;

  /// No description provided for @walletAndEarnings.
  ///
  /// In en, this message translates to:
  /// **'Wallet & Earnings'**
  String get walletAndEarnings;

  /// No description provided for @shippingCompanies.
  ///
  /// In en, this message translates to:
  /// **'Shipping Companies'**
  String get shippingCompanies;

  /// No description provided for @featureLockedDesc.
  ///
  /// In en, this message translates to:
  /// **'You must verify your supplier account first to access this feature.'**
  String get featureLockedDesc;

  /// No description provided for @verifyAccountBtn.
  ///
  /// In en, this message translates to:
  /// **'Verify Account'**
  String get verifyAccountBtn;

  /// No description provided for @overviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewTitle;

  /// No description provided for @supplierRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplier Rating'**
  String get supplierRatingLabel;

  /// No description provided for @quickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActionsTitle;

  /// No description provided for @addNewProductAction.
  ///
  /// In en, this message translates to:
  /// **'Add New Product'**
  String get addNewProductAction;

  /// No description provided for @viewNewOrdersAction.
  ///
  /// In en, this message translates to:
  /// **'View New Orders'**
  String get viewNewOrdersAction;

  /// No description provided for @withdrawBalanceAction.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Balance'**
  String get withdrawBalanceAction;

  /// No description provided for @totalVariantsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Variants'**
  String get totalVariantsLabel;

  /// No description provided for @colorsCountSuffix.
  ///
  /// In en, this message translates to:
  /// **' Colors'**
  String get colorsCountSuffix;

  /// No description provided for @stockLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock: '**
  String get stockLabel;

  /// No description provided for @costLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost: '**
  String get costLabel;

  /// No description provided for @addNewProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Product'**
  String get addNewProductTitle;

  /// No description provided for @basicInformationLabel.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformationLabel;

  /// No description provided for @tapToSelectCategoriesMsg.
  ///
  /// In en, this message translates to:
  /// **'Tap to select categories...'**
  String get tapToSelectCategoriesMsg;

  /// No description provided for @categoriesSelectedMsg.
  ///
  /// In en, this message translates to:
  /// **'{count} categories selected'**
  String categoriesSelectedMsg(String count);

  /// No description provided for @uploadFailedWithErrorMsg.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String uploadFailedWithErrorMsg(String error);

  /// No description provided for @errorOccurredWithErrorMsg.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorOccurredWithErrorMsg(String error);

  /// No description provided for @variantsAndColorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Variants & Colors'**
  String get variantsAndColorsLabel;

  /// No description provided for @addColorBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Color'**
  String get addColorBtn;

  /// No description provided for @chooseColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose Color'**
  String get chooseColorLabel;

  /// No description provided for @costPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost (SAR)'**
  String get costPriceLabel;

  /// No description provided for @addImageBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get addImageBtn;

  /// No description provided for @selectProductColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Product Color'**
  String get selectProductColorTitle;

  /// No description provided for @saveAndPublishProductBtn.
  ///
  /// In en, this message translates to:
  /// **'Save & Publish Product'**
  String get saveAndPublishProductBtn;

  /// No description provided for @noOrdersCurrentlyMsg.
  ///
  /// In en, this message translates to:
  /// **'No orders currently'**
  String get noOrdersCurrentlyMsg;

  /// No description provided for @quantityAndCustomerMsg.
  ///
  /// In en, this message translates to:
  /// **'Quantity: {quantity} | Customer: {customerName}'**
  String quantityAndCustomerMsg(String quantity, String customerName);

  /// No description provided for @addShippingCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Shipping Company'**
  String get addShippingCompanyTitle;

  /// No description provided for @editShippingCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Shipping Company'**
  String get editShippingCompanyTitle;

  /// No description provided for @enterValidDataMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid data'**
  String get enterValidDataMsg;

  /// No description provided for @deleteCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Company'**
  String get deleteCompanyTitle;

  /// No description provided for @confirmDeleteShippingCompanyDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this shipping company?'**
  String get confirmDeleteShippingCompanyDesc;

  /// No description provided for @addCompanyBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Company'**
  String get addCompanyBtn;

  /// No description provided for @numberOfAddedCompanies.
  ///
  /// In en, this message translates to:
  /// **'Added Companies Count'**
  String get numberOfAddedCompanies;

  /// No description provided for @noShippingCompaniesAddedMsg.
  ///
  /// In en, this message translates to:
  /// **'No shipping companies added'**
  String get noShippingCompaniesAddedMsg;

  /// No description provided for @uploadCertificateSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Certificate uploaded successfully ✅'**
  String get uploadCertificateSuccessMsg;

  /// No description provided for @uploadFileFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload file ❌'**
  String get uploadFileFailedMsg;

  /// No description provided for @pleaseUploadIbanCertificateMsg.
  ///
  /// In en, this message translates to:
  /// **'Please upload IBAN certificate'**
  String get pleaseUploadIbanCertificateMsg;

  /// No description provided for @dataSavedSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Data saved successfully ✅'**
  String get dataSavedSuccessMsg;

  /// No description provided for @bankNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get bankNameLabel;

  /// No description provided for @accountHolderNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Holder Name'**
  String get accountHolderNameLabel;

  /// No description provided for @ibanLabel.
  ///
  /// In en, this message translates to:
  /// **'IBAN Number'**
  String get ibanLabel;

  /// No description provided for @ibanHint.
  ///
  /// In en, this message translates to:
  /// **'SA00 0000 ...'**
  String get ibanHint;

  /// No description provided for @accountNumberOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Number (Optional)'**
  String get accountNumberOptionalLabel;

  /// No description provided for @ibanCertificateLabel.
  ///
  /// In en, this message translates to:
  /// **'IBAN Certificate'**
  String get ibanCertificateLabel;

  /// No description provided for @tapToUploadCertificateImageMsg.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload certificate image (PDF or Image)'**
  String get tapToUploadCertificateImageMsg;

  /// No description provided for @pdfFileLabel.
  ///
  /// In en, this message translates to:
  /// **'PDF File'**
  String get pdfFileLabel;

  /// No description provided for @cannotLoadImageMsg.
  ///
  /// In en, this message translates to:
  /// **'Cannot load image'**
  String get cannotLoadImageMsg;

  /// No description provided for @languageAndCurrencySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Language and Currency'**
  String get languageAndCurrencySubtitle;

  /// No description provided for @storeInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Store Information'**
  String get storeInfoTitle;

  /// No description provided for @customizeStoreIdentitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize your store identity'**
  String get customizeStoreIdentitySubtitle;

  /// No description provided for @storeImageSquareHint.
  ///
  /// In en, this message translates to:
  /// **'Store image (Logo). Preferably square.'**
  String get storeImageSquareHint;

  /// No description provided for @storeBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Store Banner'**
  String get storeBannerTitle;

  /// No description provided for @socialMediaLinksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Social Media Accounts'**
  String get socialMediaLinksSubtitle;

  /// No description provided for @emailNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailNotificationsLabel;

  /// No description provided for @receiveEmailNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications via email'**
  String get receiveEmailNotificationsSubtitle;

  /// No description provided for @appNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Instant mobile alerts'**
  String get appNotificationsSubtitle;

  /// No description provided for @smsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive text messages'**
  String get smsNotificationsSubtitle;

  /// No description provided for @showEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display email on public store page'**
  String get showEmailSubtitle;

  /// No description provided for @showPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display phone number to customers'**
  String get showPhoneSubtitle;

  /// No description provided for @specialOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Limited Time Special Offer!'**
  String get specialOfferTitle;

  /// No description provided for @specialOfferDesc.
  ///
  /// In en, this message translates to:
  /// **'Enjoy all the benefits of the advanced package for free. Start selling and scale your business with no subscription costs.'**
  String get specialOfferDesc;

  /// No description provided for @freeSubscriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Free Subscription'**
  String get freeSubscriptionLabel;

  /// No description provided for @activateFreeSubscriptionBtn.
  ///
  /// In en, this message translates to:
  /// **'Activate Your Free Subscription Now'**
  String get activateFreeSubscriptionBtn;

  /// No description provided for @freeSubscriptionActivatedMsg.
  ///
  /// In en, this message translates to:
  /// **'Free subscription activated!'**
  String get freeSubscriptionActivatedMsg;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
