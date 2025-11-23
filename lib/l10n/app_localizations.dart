import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

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
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'SWE Mobile'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Placeholder text for email input field
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailPlaceholder;

  /// Validation message for empty email field
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailRequired;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordPlaceholder;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordRequired;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create a Company'**
  String get signUp;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @navigationOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navigationOrders;

  /// No description provided for @navigationCompanies.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get navigationCompanies;

  /// No description provided for @navigationLinkings.
  ///
  /// In en, this message translates to:
  /// **'Linkings'**
  String get navigationLinkings;

  /// No description provided for @navigationCart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get navigationCart;

  /// No description provided for @navigationSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navigationSettings;

  /// No description provided for @navigationHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navigationHome;

  /// No description provided for @navigationCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get navigationCatalog;

  /// No description provided for @navigationDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navigationDashboard;

  /// No description provided for @navigationComplaints.
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get navigationComplaints;

  /// No description provided for @emailAndPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Email and password are required'**
  String get emailAndPasswordRequired;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a Company'**
  String get signupTitle;

  /// No description provided for @signupStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Company Type'**
  String get signupStep1Title;

  /// No description provided for @signupStep1Consumer.
  ///
  /// In en, this message translates to:
  /// **'Consumer'**
  String get signupStep1Consumer;

  /// No description provided for @signupStep1Supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get signupStep1Supplier;

  /// No description provided for @signupStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Owner Details'**
  String get signupStep2Title;

  /// No description provided for @signupStep2FirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get signupStep2FirstName;

  /// No description provided for @signupStep2FirstNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name'**
  String get signupStep2FirstNamePlaceholder;

  /// No description provided for @signupStep2LastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get signupStep2LastName;

  /// No description provided for @signupStep2LastNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name'**
  String get signupStep2LastNamePlaceholder;

  /// No description provided for @signupStep2PhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get signupStep2PhoneNumber;

  /// No description provided for @signupStep2PhoneNumberPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'+7-000-000-00-00'**
  String get signupStep2PhoneNumberPlaceholder;

  /// No description provided for @signupStep2Email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signupStep2Email;

  /// No description provided for @signupStep2EmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'example@mail.com'**
  String get signupStep2EmailPlaceholder;

  /// No description provided for @signupStep2Password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signupStep2Password;

  /// No description provided for @signupStep2passwordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get signupStep2passwordPlaceholder;

  /// No description provided for @signupStep2passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get signupStep2passwordRequired;

  /// No description provided for @signupStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Company Details'**
  String get signupStep3Title;

  /// No description provided for @signupStep3Name.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get signupStep3Name;

  /// No description provided for @signupStep3NamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter company name'**
  String get signupStep3NamePlaceholder;

  /// No description provided for @signupStep3Description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get signupStep3Description;

  /// No description provided for @signupStep3DescriptionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter company description'**
  String get signupStep3DescriptionPlaceholder;

  /// No description provided for @signupStep3Logo.
  ///
  /// In en, this message translates to:
  /// **'Company logo'**
  String get signupStep3Logo;

  /// No description provided for @signupStep3LogoPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select logo file'**
  String get signupStep3LogoPlaceholder;

  /// No description provided for @signupStep3Location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get signupStep3Location;

  /// No description provided for @signupStep3LocationPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select city'**
  String get signupStep3LocationPlaceholder;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get commonBackToLogin;

  /// No description provided for @errorLoadingCitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load cities'**
  String get errorLoadingCitiesTitle;

  /// No description provided for @settingsUserProfile.
  ///
  /// In en, this message translates to:
  /// **'User profile'**
  String get settingsUserProfile;

  /// No description provided for @settingsCompanyProfile.
  ///
  /// In en, this message translates to:
  /// **'Company profile'**
  String get settingsCompanyProfile;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @userProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'User profile'**
  String get userProfileTitle;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @userRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get userRole;

  /// No description provided for @userLocale.
  ///
  /// In en, this message translates to:
  /// **'Locale'**
  String get userLocale;

  /// No description provided for @companyLabel.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get companyLabel;

  /// No description provided for @refreshProfile.
  ///
  /// In en, this message translates to:
  /// **'Refresh profile'**
  String get refreshProfile;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get errorLoadingProfile;

  /// No description provided for @noUserProfile.
  ///
  /// In en, this message translates to:
  /// **'No user profile available'**
  String get noUserProfile;

  /// No description provided for @companyProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Company profile'**
  String get companyProfileTitle;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get companyName;

  /// No description provided for @companyLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get companyLocation;

  /// No description provided for @companyType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get companyType;

  /// No description provided for @companyDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get companyDescription;

  /// No description provided for @companyId.
  ///
  /// In en, this message translates to:
  /// **'Company ID'**
  String get companyId;

  /// No description provided for @refreshCompany.
  ///
  /// In en, this message translates to:
  /// **'Refresh company'**
  String get refreshCompany;

  /// No description provided for @errorLoadingCompany.
  ///
  /// In en, this message translates to:
  /// **'Failed to load company'**
  String get errorLoadingCompany;

  /// No description provided for @noCompanyProfile.
  ///
  /// In en, this message translates to:
  /// **'No company profile available'**
  String get noCompanyProfile;

  /// No description provided for @companyTypeSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get companyTypeSupplier;

  /// No description provided for @companyTypeConsumer.
  ///
  /// In en, this message translates to:
  /// **'Consumer'**
  String get companyTypeConsumer;

  /// No description provided for @settingsStaffManagement.
  ///
  /// In en, this message translates to:
  /// **'Staff Management'**
  String get settingsStaffManagement;

  /// No description provided for @staffManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff Management'**
  String get staffManagementTitle;

  /// No description provided for @catalogCreateProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Create product'**
  String get catalogCreateProductTitle;

  /// No description provided for @catalogProductNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get catalogProductNameLabel;

  /// No description provided for @catalogProductDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get catalogProductDescriptionLabel;

  /// No description provided for @catalogProductStockQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock quantity'**
  String get catalogProductStockQuantityLabel;

  /// No description provided for @catalogProductRetailPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Retail price'**
  String get catalogProductRetailPriceLabel;

  /// No description provided for @catalogProductThresholdLabel.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get catalogProductThresholdLabel;

  /// No description provided for @catalogProductBulkPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Bulk price'**
  String get catalogProductBulkPriceLabel;

  /// No description provided for @catalogProductMinimumOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum order'**
  String get catalogProductMinimumOrderLabel;

  /// No description provided for @catalogProductUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get catalogProductUnitLabel;

  /// No description provided for @catalogProductImagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Product images'**
  String get catalogProductImagesLabel;

  /// No description provided for @catalogProductImagesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select product images (up to 5)'**
  String get catalogProductImagesPlaceholder;

  /// No description provided for @catalogProductImagesMaxExceededTitle.
  ///
  /// In en, this message translates to:
  /// **'Maximum images reached'**
  String get catalogProductImagesMaxExceededTitle;

  /// No description provided for @catalogProductImagesMaxExceededMessage.
  ///
  /// In en, this message translates to:
  /// **'You can only add up to 5 images. Some images were not added.'**
  String get catalogProductImagesMaxExceededMessage;

  /// No description provided for @catalogCreateProductSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product created successfully'**
  String get catalogCreateProductSuccess;

  /// No description provided for @catalogCreateProductErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Failed to create product: {error}'**
  String catalogCreateProductErrorGeneric(Object error);

  /// No description provided for @catalogEditProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get catalogEditProductTitle;

  /// No description provided for @catalogUpdateProductSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product updated successfully'**
  String get catalogUpdateProductSuccess;

  /// No description provided for @catalogUpdateProductErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Failed to update product: {error}'**
  String catalogUpdateProductErrorGeneric(Object error);

  /// No description provided for @catalogDeleteProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete product'**
  String get catalogDeleteProductTitle;

  /// No description provided for @catalogDeleteProductMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this product? This action cannot be undone.'**
  String get catalogDeleteProductMessage;

  /// No description provided for @catalogDeleteProductSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product deleted successfully'**
  String get catalogDeleteProductSuccess;

  /// No description provided for @catalogDeleteProductErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete product: {error}'**
  String catalogDeleteProductErrorGeneric(Object error);

  /// No description provided for @staffCreateUserSuccess.
  ///
  /// In en, this message translates to:
  /// **'User created successfully'**
  String get staffCreateUserSuccess;

  /// No description provided for @staffDeleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete user'**
  String get staffDeleteUserTitle;

  /// No description provided for @staffDeleteUserMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this user? This action cannot be undone.'**
  String get staffDeleteUserMessage;

  /// No description provided for @staffDeleteUserSuccess.
  ///
  /// In en, this message translates to:
  /// **'User deleted successfully'**
  String get staffDeleteUserSuccess;

  /// No description provided for @staffDeleteUserErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete user: {error}'**
  String staffDeleteUserErrorGeneric(Object error);

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @chatTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatTypeMessage;

  /// No description provided for @chatCannotSendMessages.
  ///
  /// In en, this message translates to:
  /// **'Cannot send messages'**
  String get chatCannotSendMessages;

  /// No description provided for @chatLoadingPermissions.
  ///
  /// In en, this message translates to:
  /// **'Loading permissions...'**
  String get chatLoadingPermissions;

  /// No description provided for @chatErrorLoadingPermissions.
  ///
  /// In en, this message translates to:
  /// **'Error loading permissions'**
  String get chatErrorLoadingPermissions;

  /// No description provided for @chatOnlyConsumerContact.
  ///
  /// In en, this message translates to:
  /// **'Only consumer contact can send messages'**
  String get chatOnlyConsumerContact;

  /// No description provided for @chatOnlyAssignedSalesman.
  ///
  /// In en, this message translates to:
  /// **'Only assigned salesman can send messages'**
  String get chatOnlyAssignedSalesman;

  /// No description provided for @chatAttachmentImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get chatAttachmentImage;

  /// No description provided for @chatAttachmentFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get chatAttachmentFile;

  /// No description provided for @chatAttachmentAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get chatAttachmentAudio;

  /// No description provided for @chatSelectImageSource.
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get chatSelectImageSource;

  /// No description provided for @chatImageSourceGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get chatImageSourceGallery;

  /// No description provided for @chatImageSourceCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get chatImageSourceCamera;

  /// No description provided for @chatErrorUploadFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload file: {error}'**
  String chatErrorUploadFile(Object error);

  /// No description provided for @chatErrorUploadAudio.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload audio: {error}'**
  String chatErrorUploadAudio(Object error);

  /// No description provided for @chatErrorUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image: {error}'**
  String chatErrorUploadImage(Object error);

  /// No description provided for @chatMicrophonePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied'**
  String get chatMicrophonePermissionDenied;

  /// No description provided for @chatErrorStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Failed to start recording: {error}'**
  String chatErrorStartRecording(Object error);

  /// No description provided for @chatRecordingFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Recording file not found'**
  String get chatRecordingFileNotFound;

  /// No description provided for @chatErrorProcessRecording.
  ///
  /// In en, this message translates to:
  /// **'Failed to process recording: {error}'**
  String chatErrorProcessRecording(Object error);

  /// No description provided for @chatErrorSendImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send image: {error}'**
  String chatErrorSendImage(Object error);

  /// No description provided for @chatErrorSendFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to send file: {error}'**
  String chatErrorSendFile(Object error);

  /// No description provided for @chatErrorSendAudio.
  ///
  /// In en, this message translates to:
  /// **'Failed to send audio: {error}'**
  String chatErrorSendAudio(Object error);

  /// No description provided for @chatErrorSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message: {error}'**
  String chatErrorSendMessage(Object error);

  /// No description provided for @chatCannotOpenFileUrl.
  ///
  /// In en, this message translates to:
  /// **'Cannot open file URL'**
  String get chatCannotOpenFileUrl;

  /// No description provided for @chatErrorDownloadFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to download file: {error}'**
  String chatErrorDownloadFile(Object error);

  /// No description provided for @chatErrorPlayAudio.
  ///
  /// In en, this message translates to:
  /// **'Failed to play audio: {error}'**
  String chatErrorPlayAudio(Object error);

  /// No description provided for @chatNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatNoMessages;

  /// No description provided for @chatError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String chatError(Object error);

  /// No description provided for @chatAttachFile.
  ///
  /// In en, this message translates to:
  /// **'Attach file'**
  String get chatAttachFile;

  /// No description provided for @chatDownloadFile.
  ///
  /// In en, this message translates to:
  /// **'Download file'**
  String get chatDownloadFile;

  /// No description provided for @chatPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get chatPause;

  /// No description provided for @chatPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get chatPlay;

  /// No description provided for @chatStopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get chatStopRecording;

  /// No description provided for @chatRecordAudio.
  ///
  /// In en, this message translates to:
  /// **'Record audio'**
  String get chatRecordAudio;

  /// No description provided for @chatFailedToLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get chatFailedToLoadImage;

  /// No description provided for @chatUserUnknown.
  ///
  /// In en, this message translates to:
  /// **'User {userId}'**
  String chatUserUnknown(Object userId);

  /// No description provided for @chatOrderCreated.
  ///
  /// In en, this message translates to:
  /// **'Order #{orderId} created with status {status}'**
  String chatOrderCreated(Object orderId, Object status);

  /// No description provided for @chatOrderCreatedNoId.
  ///
  /// In en, this message translates to:
  /// **'Order created with status {status}'**
  String chatOrderCreatedNoId(Object status);

  /// No description provided for @chatComplaintCreated.
  ///
  /// In en, this message translates to:
  /// **'Complaint #{complaintId} created with status {status}'**
  String chatComplaintCreated(Object complaintId, Object status);

  /// No description provided for @chatComplaintCreatedNoId.
  ///
  /// In en, this message translates to:
  /// **'Complaint created with status {status}'**
  String chatComplaintCreatedNoId(Object status);

  /// No description provided for @chatOrderStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Order #{orderId} status changed from {oldStatus} to {newStatus}'**
  String chatOrderStatusChanged(
    Object newStatus,
    Object oldStatus,
    Object orderId,
  );

  /// No description provided for @chatOrderStatusChangedNoId.
  ///
  /// In en, this message translates to:
  /// **'Order status changed from {oldStatus} to {newStatus}'**
  String chatOrderStatusChangedNoId(Object newStatus, Object oldStatus);

  /// No description provided for @chatComplaintStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Complaint #{complaintId} status changed from {oldStatus} to {newStatus}'**
  String chatComplaintStatusChanged(
    Object complaintId,
    Object newStatus,
    Object oldStatus,
  );

  /// No description provided for @chatComplaintStatusChangedNoId.
  ///
  /// In en, this message translates to:
  /// **'Complaint status changed from {oldStatus} to {newStatus}'**
  String chatComplaintStatusChangedNoId(Object newStatus, Object oldStatus);

  /// No description provided for @chatOrderStatusRemoved.
  ///
  /// In en, this message translates to:
  /// **'Order #{orderId} status removed (was {oldStatus})'**
  String chatOrderStatusRemoved(Object oldStatus, Object orderId);

  /// No description provided for @chatOrderStatusRemovedNoId.
  ///
  /// In en, this message translates to:
  /// **'Order status removed (was {oldStatus})'**
  String chatOrderStatusRemovedNoId(Object oldStatus);

  /// No description provided for @chatComplaintStatusRemoved.
  ///
  /// In en, this message translates to:
  /// **'Complaint #{complaintId} status removed (was {oldStatus})'**
  String chatComplaintStatusRemoved(Object complaintId, Object oldStatus);

  /// No description provided for @chatComplaintStatusRemovedNoId.
  ///
  /// In en, this message translates to:
  /// **'Complaint status removed (was {oldStatus})'**
  String chatComplaintStatusRemovedNoId(Object oldStatus);

  /// No description provided for @chatBySender.
  ///
  /// In en, this message translates to:
  /// **'By {senderName}'**
  String chatBySender(Object senderName);

  /// No description provided for @complaintDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Complaint Details'**
  String get complaintDetailsTitle;

  /// No description provided for @complaintNotFound.
  ///
  /// In en, this message translates to:
  /// **'Complaint not found'**
  String get complaintNotFound;

  /// No description provided for @complaintInformation.
  ///
  /// In en, this message translates to:
  /// **'Complaint Information'**
  String get complaintInformation;

  /// No description provided for @complaintDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get complaintDescription;

  /// No description provided for @complaintCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get complaintCreated;

  /// No description provided for @complaintUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get complaintUpdated;

  /// No description provided for @complaintResolutionNotes.
  ///
  /// In en, this message translates to:
  /// **'Resolution Notes'**
  String get complaintResolutionNotes;

  /// No description provided for @complaintOrderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order Cancelled'**
  String get complaintOrderCancelled;

  /// No description provided for @complaintAssignedPersonnel.
  ///
  /// In en, this message translates to:
  /// **'Assigned Personnel'**
  String get complaintAssignedPersonnel;

  /// No description provided for @complaintAssignedSalesman.
  ///
  /// In en, this message translates to:
  /// **'Assigned Salesman'**
  String get complaintAssignedSalesman;

  /// No description provided for @complaintAssignedManager.
  ///
  /// In en, this message translates to:
  /// **'Assigned Manager'**
  String get complaintAssignedManager;

  /// No description provided for @complaintNoManagerAssigned.
  ///
  /// In en, this message translates to:
  /// **'No manager assigned'**
  String get complaintNoManagerAssigned;

  /// No description provided for @complaintNoPersonnelAssigned.
  ///
  /// In en, this message translates to:
  /// **'No personnel assigned'**
  String get complaintNoPersonnelAssigned;

  /// No description provided for @complaintHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get complaintHistory;

  /// No description provided for @complaintNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No history available'**
  String get complaintNoHistory;

  /// No description provided for @complaintOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open Chat'**
  String get complaintOpenChat;

  /// No description provided for @complaintActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get complaintActions;

  /// No description provided for @complaintEscalateToManager.
  ///
  /// In en, this message translates to:
  /// **'Escalate to Manager'**
  String get complaintEscalateToManager;

  /// No description provided for @complaintResolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get complaintResolve;

  /// No description provided for @complaintClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get complaintClose;

  /// No description provided for @complaintClaimComplaint.
  ///
  /// In en, this message translates to:
  /// **'Claim Complaint'**
  String get complaintClaimComplaint;

  /// No description provided for @complaintEscalateTitle.
  ///
  /// In en, this message translates to:
  /// **'Escalate Complaint'**
  String get complaintEscalateTitle;

  /// No description provided for @complaintEscalateNotes.
  ///
  /// In en, this message translates to:
  /// **'Optional: Add notes explaining why you are escalating:'**
  String get complaintEscalateNotes;

  /// No description provided for @complaintEscalateNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get complaintEscalateNotesLabel;

  /// No description provided for @complaintEscalate.
  ///
  /// In en, this message translates to:
  /// **'Escalate'**
  String get complaintEscalate;

  /// No description provided for @complaintEscalatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Complaint escalated successfully'**
  String get complaintEscalatedSuccess;

  /// No description provided for @complaintEscalateError.
  ///
  /// In en, this message translates to:
  /// **'Error escalating complaint: {error}'**
  String complaintEscalateError(Object error);

  /// No description provided for @complaintClaimTitle.
  ///
  /// In en, this message translates to:
  /// **'Claim Complaint'**
  String get complaintClaimTitle;

  /// No description provided for @complaintClaimMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to claim this complaint? You will be responsible for managing it.'**
  String get complaintClaimMessage;

  /// No description provided for @complaintClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get complaintClaim;

  /// No description provided for @complaintClaimedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Complaint claimed successfully'**
  String get complaintClaimedSuccess;

  /// No description provided for @complaintClaimError.
  ///
  /// In en, this message translates to:
  /// **'Error claiming complaint: {error}'**
  String complaintClaimError(Object error);

  /// No description provided for @complaintResolveTitle.
  ///
  /// In en, this message translates to:
  /// **'Resolve Complaint'**
  String get complaintResolveTitle;

  /// No description provided for @complaintResolveNotes.
  ///
  /// In en, this message translates to:
  /// **'Please provide resolution notes:'**
  String get complaintResolveNotes;

  /// No description provided for @complaintResolveNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Resolution Notes'**
  String get complaintResolveNotesLabel;

  /// No description provided for @complaintCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get complaintCancelOrder;

  /// No description provided for @complaintResolveNotesRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter resolution notes'**
  String get complaintResolveNotesRequired;

  /// No description provided for @complaintResolvedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Complaint resolved successfully'**
  String get complaintResolvedSuccess;

  /// No description provided for @complaintResolveError.
  ///
  /// In en, this message translates to:
  /// **'Error resolving complaint: {error}'**
  String complaintResolveError(Object error);

  /// No description provided for @complaintCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Close Complaint'**
  String get complaintCloseTitle;

  /// No description provided for @complaintCloseNotes.
  ///
  /// In en, this message translates to:
  /// **'Please provide notes explaining why the complaint is being closed:'**
  String get complaintCloseNotes;

  /// No description provided for @complaintClosedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Complaint closed successfully'**
  String get complaintClosedSuccess;

  /// No description provided for @complaintCloseError.
  ///
  /// In en, this message translates to:
  /// **'Error closing complaint: {error}'**
  String complaintCloseError(Object error);

  /// No description provided for @complaintByUser.
  ///
  /// In en, this message translates to:
  /// **'By: {userName}'**
  String complaintByUser(Object userName);

  /// No description provided for @complaintStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get complaintStatusOpen;

  /// No description provided for @complaintStatusEscalated.
  ///
  /// In en, this message translates to:
  /// **'ESCALATED'**
  String get complaintStatusEscalated;

  /// No description provided for @complaintStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'IN PROGRESS'**
  String get complaintStatusInProgress;

  /// No description provided for @complaintStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'RESOLVED'**
  String get complaintStatusResolved;

  /// No description provided for @complaintStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'CLOSED'**
  String get complaintStatusClosed;

  /// No description provided for @orderDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetailsTitle;

  /// No description provided for @orderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderNotFound;

  /// No description provided for @orderLinking.
  ///
  /// In en, this message translates to:
  /// **'Linking'**
  String get orderLinking;

  /// No description provided for @orderCreateComplaint.
  ///
  /// In en, this message translates to:
  /// **'Create Complaint'**
  String get orderCreateComplaint;

  /// No description provided for @orderCreateComplaintReason.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for your complaint:'**
  String get orderCreateComplaintReason;

  /// No description provided for @orderComplaintReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason of Complaint'**
  String get orderComplaintReasonLabel;

  /// No description provided for @orderComplaintReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reason for the complaint'**
  String get orderComplaintReasonRequired;

  /// No description provided for @orderComplaintCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Complaint created successfully'**
  String get orderComplaintCreatedSuccess;

  /// No description provided for @orderComplaintCreateError.
  ///
  /// In en, this message translates to:
  /// **'Error creating complaint: {error}'**
  String orderComplaintCreateError(Object error);

  /// No description provided for @orderChangeStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Order Status'**
  String get orderChangeStatusTitle;

  /// No description provided for @orderChangeStatusMessage.
  ///
  /// In en, this message translates to:
  /// **'Change order status from \"{oldStatus}\" to \"{newStatus}\"?'**
  String orderChangeStatusMessage(Object newStatus, Object oldStatus);

  /// No description provided for @orderChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get orderChange;

  /// No description provided for @orderStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Order status changed to {status}'**
  String orderStatusChanged(Object status);

  /// No description provided for @orderStatusChangeError.
  ///
  /// In en, this message translates to:
  /// **'Error changing order status: {error}'**
  String orderStatusChangeError(Object error);

  /// No description provided for @orderCreated.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String orderCreated(Object date);

  /// No description provided for @orderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated: {date}'**
  String orderUpdated(Object date);

  /// No description provided for @orderComplaint.
  ///
  /// In en, this message translates to:
  /// **'Complaint'**
  String get orderComplaint;

  /// No description provided for @orderProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get orderProducts;

  /// No description provided for @orderNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No products in this order'**
  String get orderNoProducts;

  /// No description provided for @orderTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get orderTotal;

  /// No description provided for @orderQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity: {quantity}'**
  String orderQuantity(Object quantity);

  /// No description provided for @orderPricePerUnit.
  ///
  /// In en, this message translates to:
  /// **'Price per unit: {price} ₸'**
  String orderPricePerUnit(Object price);

  /// No description provided for @orderSubtotal.
  ///
  /// In en, this message translates to:
  /// **'{subtotal} ₸'**
  String orderSubtotal(Object subtotal);

  /// No description provided for @orderProductId.
  ///
  /// In en, this message translates to:
  /// **'Product #{productId}'**
  String orderProductId(Object productId);

  /// No description provided for @orderSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get orderSupplier;

  /// No description provided for @orderConsumer.
  ///
  /// In en, this message translates to:
  /// **'Consumer'**
  String get orderConsumer;

  /// No description provided for @orderAssignedSalesperson.
  ///
  /// In en, this message translates to:
  /// **'Assigned Salesperson'**
  String get orderAssignedSalesperson;

  /// No description provided for @orderConsumerStaff.
  ///
  /// In en, this message translates to:
  /// **'Consumer Staff'**
  String get orderConsumerStaff;

  /// No description provided for @companiesCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get companiesCompany;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @linkingsPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get linkingsPending;

  /// No description provided for @linkingsAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get linkingsAccepted;

  /// No description provided for @linkingsRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get linkingsRejected;

  /// No description provided for @linkingsUnlinked.
  ///
  /// In en, this message translates to:
  /// **'Unlinked'**
  String get linkingsUnlinked;

  /// No description provided for @linkingsNoLinkings.
  ///
  /// In en, this message translates to:
  /// **'No linkings found'**
  String get linkingsNoLinkings;

  /// No description provided for @linkingsNoCompaniesMatch.
  ///
  /// In en, this message translates to:
  /// **'No companies found matching \"{query}\"'**
  String linkingsNoCompaniesMatch(Object query);

  /// No description provided for @linkingsSearchCompanies.
  ///
  /// In en, this message translates to:
  /// **'Search companies...'**
  String get linkingsSearchCompanies;

  /// No description provided for @linkingsMessage.
  ///
  /// In en, this message translates to:
  /// **'Message: {message}'**
  String linkingsMessage(Object message);

  /// No description provided for @linkingsCreated.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String linkingsCreated(Object date);

  /// No description provided for @linkingsAcceptedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Linking accepted'**
  String get linkingsAcceptedSuccess;

  /// No description provided for @linkingsAcceptError.
  ///
  /// In en, this message translates to:
  /// **'Error accepting linking: {error}'**
  String linkingsAcceptError(Object error);

  /// No description provided for @linkingsRejectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Linking rejected'**
  String get linkingsRejectedSuccess;

  /// No description provided for @linkingsRejectError.
  ///
  /// In en, this message translates to:
  /// **'Error rejecting linking: {error}'**
  String linkingsRejectError(Object error);

  /// No description provided for @linkingsDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Linking Details'**
  String get linkingsDetailsTitle;

  /// No description provided for @linkingsFailedToLoadCompany.
  ///
  /// In en, this message translates to:
  /// **'Failed to load company'**
  String get linkingsFailedToLoadCompany;

  /// No description provided for @linkingsFailedToLoadContactPerson.
  ///
  /// In en, this message translates to:
  /// **'Failed to load contact person'**
  String get linkingsFailedToLoadContactPerson;

  /// No description provided for @linkingsFailedToLoadSalesperson.
  ///
  /// In en, this message translates to:
  /// **'Failed to load salesperson'**
  String get linkingsFailedToLoadSalesperson;

  /// No description provided for @linkingsCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get linkingsCompany;

  /// No description provided for @linkingsConsumerContact.
  ///
  /// In en, this message translates to:
  /// **'Consumer Contact'**
  String get linkingsConsumerContact;

  /// No description provided for @linkingsSupplierContact.
  ///
  /// In en, this message translates to:
  /// **'Supplier Contact (Assigned Salesperson)'**
  String get linkingsSupplierContact;

  /// No description provided for @linkingsOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open Chat'**
  String get linkingsOpenChat;

  /// No description provided for @linkingsUnlinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlink Companies'**
  String get linkingsUnlinkTitle;

  /// No description provided for @linkingsUnlinkMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unlink these companies? This action cannot be undone.'**
  String get linkingsUnlinkMessage;

  /// No description provided for @linkingsUnlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get linkingsUnlink;

  /// No description provided for @linkingsUnlinkedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Companies unlinked'**
  String get linkingsUnlinkedSuccess;

  /// No description provided for @linkingsUnlinkError.
  ///
  /// In en, this message translates to:
  /// **'Error unlinking: {error}'**
  String linkingsUnlinkError(Object error);

  /// No description provided for @linkingsReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get linkingsReject;

  /// No description provided for @linkingsAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get linkingsAccept;

  /// No description provided for @supplierComplaintsNoAssigned.
  ///
  /// In en, this message translates to:
  /// **'No assigned complaints'**
  String get supplierComplaintsNoAssigned;

  /// No description provided for @supplierComplaintsNoEscalated.
  ///
  /// In en, this message translates to:
  /// **'No escalated complaints'**
  String get supplierComplaintsNoEscalated;

  /// No description provided for @supplierComplaintsNoManaged.
  ///
  /// In en, this message translates to:
  /// **'No managed complaints'**
  String get supplierComplaintsNoManaged;

  /// No description provided for @supplierComplaintsNoComplaints.
  ///
  /// In en, this message translates to:
  /// **'No complaints'**
  String get supplierComplaintsNoComplaints;

  /// No description provided for @supplierComplaintsNoLinkingsComplaints.
  ///
  /// In en, this message translates to:
  /// **'No complaints for your linkings'**
  String get supplierComplaintsNoLinkingsComplaints;

  /// No description provided for @supplierComplaintsEscalated.
  ///
  /// In en, this message translates to:
  /// **'Escalated'**
  String get supplierComplaintsEscalated;

  /// No description provided for @supplierComplaintsMyManaged.
  ///
  /// In en, this message translates to:
  /// **'My Managed'**
  String get supplierComplaintsMyManaged;

  /// No description provided for @supplierComplaintsAllComplaints.
  ///
  /// In en, this message translates to:
  /// **'All Complaints'**
  String get supplierComplaintsAllComplaints;

  /// No description provided for @supplierComplaintsMyLinkings.
  ///
  /// In en, this message translates to:
  /// **'My Linkings'**
  String get supplierComplaintsMyLinkings;

  /// No description provided for @supplierComplaintsClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get supplierComplaintsClaim;

  /// No description provided for @supplierComplaintsUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get supplierComplaintsUserNotFound;

  /// No description provided for @supplierComplaintsUnknownRole.
  ///
  /// In en, this message translates to:
  /// **'Unknown user role'**
  String get supplierComplaintsUnknownRole;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardRevenueTrend.
  ///
  /// In en, this message translates to:
  /// **'Revenue Trend'**
  String get dashboardRevenueTrend;

  /// No description provided for @dashboardOrderStatus.
  ///
  /// In en, this message translates to:
  /// **'Order Status'**
  String get dashboardOrderStatus;

  /// No description provided for @dashboardRecentOrders.
  ///
  /// In en, this message translates to:
  /// **'Recent Orders'**
  String get dashboardRecentOrders;

  /// No description provided for @dashboardLowStockAlert.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alert'**
  String get dashboardLowStockAlert;

  /// No description provided for @dashboardTotalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get dashboardTotalRevenue;

  /// No description provided for @dashboardOrdersToday.
  ///
  /// In en, this message translates to:
  /// **'Orders Today'**
  String get dashboardOrdersToday;

  /// No description provided for @dashboardCreatedOrders.
  ///
  /// In en, this message translates to:
  /// **'Created Orders'**
  String get dashboardCreatedOrders;

  /// No description provided for @dashboardLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get dashboardLowStock;

  /// No description provided for @dashboardNoRevenueData.
  ///
  /// In en, this message translates to:
  /// **'No revenue data available'**
  String get dashboardNoRevenueData;

  /// No description provided for @dashboardNoOrderData.
  ///
  /// In en, this message translates to:
  /// **'No order data available'**
  String get dashboardNoOrderData;

  /// No description provided for @dashboardNoRecentOrders.
  ///
  /// In en, this message translates to:
  /// **'No recent orders'**
  String get dashboardNoRecentOrders;

  /// No description provided for @dashboardNoLowStockAlerts.
  ///
  /// In en, this message translates to:
  /// **'No low stock alerts'**
  String get dashboardNoLowStockAlerts;

  /// No description provided for @dashboardErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading dashboard: {error}'**
  String dashboardErrorLoading(Object error);

  /// No description provided for @dashboardStock.
  ///
  /// In en, this message translates to:
  /// **'Stock: {current} / {threshold}'**
  String dashboardStock(Object current, Object threshold);

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmpty;

  /// No description provided for @cartEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add products from companies to get started'**
  String get cartEmptyMessage;

  /// No description provided for @cartFailedToLoadProducts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load products'**
  String get cartFailedToLoadProducts;

  /// No description provided for @cartCheckout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get cartCheckout;

  /// No description provided for @cartConfirmCheckout.
  ///
  /// In en, this message translates to:
  /// **'Confirm Checkout'**
  String get cartConfirmCheckout;

  /// No description provided for @cartCheckoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Complete order with {companyName}?'**
  String cartCheckoutMessage(Object companyName);

  /// No description provided for @cartTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {total} ₸'**
  String cartTotal(Object total);

  /// No description provided for @cartItems.
  ///
  /// In en, this message translates to:
  /// **'Items: {count}'**
  String cartItems(Object count);

  /// No description provided for @cartUserCompanyNotFound.
  ///
  /// In en, this message translates to:
  /// **'User company not found'**
  String get cartUserCompanyNotFound;

  /// No description provided for @cartVerifyLinkingError.
  ///
  /// In en, this message translates to:
  /// **'Failed to verify linking: {error}'**
  String cartVerifyLinkingError(Object error);

  /// No description provided for @cartLinkingNotAccepted.
  ///
  /// In en, this message translates to:
  /// **'Linking with this supplier is not accepted'**
  String get cartLinkingNotAccepted;

  /// No description provided for @cartNoValidProducts.
  ///
  /// In en, this message translates to:
  /// **'No valid products to order'**
  String get cartNoValidProducts;

  /// No description provided for @cartOrderCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order created successfully'**
  String get cartOrderCreatedSuccess;

  /// No description provided for @cartOrderCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create order: {error}'**
  String cartOrderCreateError(Object error);

  /// No description provided for @cartErrorLoadingCompany.
  ///
  /// In en, this message translates to:
  /// **'Error loading company: {error}'**
  String cartErrorLoadingCompany(Object error);

  /// No description provided for @cartTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total: {total} ₸'**
  String cartTotalLabel(Object total);

  /// No description provided for @cartPricePerUnit.
  ///
  /// In en, this message translates to:
  /// **'{price} ₸ / {unit}'**
  String cartPricePerUnit(Object price, Object unit);

  /// No description provided for @cartItemTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {total} ₸'**
  String cartItemTotal(Object total);

  /// No description provided for @cartRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get cartRemove;

  /// No description provided for @cartQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity ({unit})'**
  String cartQuantity(Object unit);

  /// No description provided for @companiesSearchCompanies.
  ///
  /// In en, this message translates to:
  /// **'Search companies...'**
  String get companiesSearchCompanies;

  /// No description provided for @companiesErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading companies'**
  String get companiesErrorLoading;

  /// No description provided for @companiesNoCompanies.
  ///
  /// In en, this message translates to:
  /// **'No companies yet'**
  String get companiesNoCompanies;

  /// No description provided for @companiesNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No companies found matching \"{query}\"'**
  String companiesNoMatch(Object query);

  /// No description provided for @companiesDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Company Details'**
  String get companiesDetailsTitle;

  /// No description provided for @companiesFailedToFetch.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch'**
  String get companiesFailedToFetch;

  /// No description provided for @companiesDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get companiesDescription;

  /// No description provided for @companiesProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get companiesProducts;

  /// No description provided for @companiesNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No products available'**
  String get companiesNoProducts;

  /// No description provided for @companiesSendLinking.
  ///
  /// In en, this message translates to:
  /// **'Send Linking'**
  String get companiesSendLinking;

  /// No description provided for @companiesLinkingPending.
  ///
  /// In en, this message translates to:
  /// **'Linking Pending'**
  String get companiesLinkingPending;

  /// No description provided for @companiesLinkingRejected.
  ///
  /// In en, this message translates to:
  /// **'Linking Rejected'**
  String get companiesLinkingRejected;

  /// No description provided for @companiesUnlinked.
  ///
  /// In en, this message translates to:
  /// **'Unlinked'**
  String get companiesUnlinked;

  /// No description provided for @companiesSendLinkingRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Linking Request'**
  String get companiesSendLinkingRequest;

  /// No description provided for @companiesLinkingMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get companiesLinkingMessage;

  /// No description provided for @companiesLinkingMessagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your message...'**
  String get companiesLinkingMessagePlaceholder;

  /// No description provided for @companiesLinkingMessageRequired.
  ///
  /// In en, this message translates to:
  /// **'Message cannot be empty'**
  String get companiesLinkingMessageRequired;

  /// No description provided for @companiesLinkingRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Linking request sent successfully'**
  String get companiesLinkingRequestSent;

  /// No description provided for @companiesLinkingRequestError.
  ///
  /// In en, this message translates to:
  /// **'Error sending linking request: {error}'**
  String companiesLinkingRequestError(Object error);

  /// No description provided for @ordersNoLinkings.
  ///
  /// In en, this message translates to:
  /// **'No linkings found'**
  String get ordersNoLinkings;

  /// No description provided for @ordersNoOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders'**
  String get ordersNoOrders;

  /// No description provided for @ordersNoOrdersStatus.
  ///
  /// In en, this message translates to:
  /// **'No orders with status: {status}'**
  String ordersNoOrdersStatus(Object status);

  /// No description provided for @ordersNoCompaniesMatch.
  ///
  /// In en, this message translates to:
  /// **'No companies found matching \"{query}\"'**
  String ordersNoCompaniesMatch(Object query);

  /// No description provided for @ordersSearchCompanies.
  ///
  /// In en, this message translates to:
  /// **'Search companies...'**
  String get ordersSearchCompanies;

  /// No description provided for @ordersAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ordersAll;

  /// No description provided for @ordersLinkingNumber.
  ///
  /// In en, this message translates to:
  /// **'Linking #{linkingId}'**
  String ordersLinkingNumber(Object linkingId);

  /// No description provided for @ordersOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{orderId}'**
  String ordersOrderNumber(Object orderId);

  /// No description provided for @ordersCreated.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String ordersCreated(Object date);

  /// No description provided for @productDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetailsTitle;

  /// No description provided for @productAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get productAddToCart;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get productDetails;

  /// No description provided for @productUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get productUnit;

  /// No description provided for @productStockQuantity.
  ///
  /// In en, this message translates to:
  /// **'Stock quantity'**
  String get productStockQuantity;

  /// No description provided for @productRetailPrice.
  ///
  /// In en, this message translates to:
  /// **'Retail price'**
  String get productRetailPrice;

  /// No description provided for @productBulkPrice.
  ///
  /// In en, this message translates to:
  /// **'Bulk price'**
  String get productBulkPrice;

  /// No description provided for @productMinimumOrder.
  ///
  /// In en, this message translates to:
  /// **'Minimum order'**
  String get productMinimumOrder;

  /// No description provided for @productThreshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get productThreshold;

  /// No description provided for @productAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added {quantity} {unit} to cart'**
  String productAddedToCart(Object quantity, Object unit);

  /// No description provided for @catalogNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get catalogNoProducts;

  /// No description provided for @catalogNoProductsMatch.
  ///
  /// In en, this message translates to:
  /// **'No products found matching \"{query}\"'**
  String catalogNoProductsMatch(Object query);

  /// No description provided for @catalogSearchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get catalogSearchProducts;

  /// No description provided for @catalogStock.
  ///
  /// In en, this message translates to:
  /// **'Stock: {quantity}'**
  String catalogStock(Object quantity);

  /// No description provided for @catalogUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User profile or company ID not found.'**
  String get catalogUserNotFound;

  /// No description provided for @catalogCompanyNotFound.
  ///
  /// In en, this message translates to:
  /// **'Company not found.'**
  String get catalogCompanyNotFound;

  /// No description provided for @catalogSupplierOnly.
  ///
  /// In en, this message translates to:
  /// **'Catalog is available for suppliers only.'**
  String get catalogSupplierOnly;

  /// No description provided for @addToCartTitle.
  ///
  /// In en, this message translates to:
  /// **'{productName}'**
  String addToCartTitle(Object productName);

  /// No description provided for @addToCartPricePerUnit.
  ///
  /// In en, this message translates to:
  /// **'Price per {unit}:'**
  String addToCartPricePerUnit(Object unit);

  /// No description provided for @addToCartQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity ({unit})'**
  String addToCartQuantity(Object unit);

  /// No description provided for @addToCartEnterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity'**
  String get addToCartEnterQuantity;

  /// No description provided for @addToCartQuantityRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a quantity'**
  String get addToCartQuantityRequired;

  /// No description provided for @addToCartInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get addToCartInvalidNumber;

  /// No description provided for @addToCartQuantityGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be greater than 0'**
  String get addToCartQuantityGreaterThanZero;

  /// No description provided for @addToCartMinimumOrder.
  ///
  /// In en, this message translates to:
  /// **'Minimum order is {minimum} {unit}'**
  String addToCartMinimumOrder(Object minimum, Object unit);

  /// No description provided for @addToCartOnlyAvailable.
  ///
  /// In en, this message translates to:
  /// **'Only {stock} {unit} available'**
  String addToCartOnlyAvailable(Object stock, Object unit);

  /// No description provided for @addToCartAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available: {stock} {unit}'**
  String addToCartAvailable(Object stock, Object unit);

  /// No description provided for @addToCartMinimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum: {minimum} {unit}'**
  String addToCartMinimum(Object minimum, Object unit);

  /// No description provided for @addToCartButton.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCartButton;

  /// No description provided for @settingsEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsEnglish;

  /// No description provided for @settingsRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get settingsRussian;

  /// No description provided for @settingsKazakh.
  ///
  /// In en, this message translates to:
  /// **'Қазақша'**
  String get settingsKazakh;

  /// No description provided for @settingsSignupFailed.
  ///
  /// In en, this message translates to:
  /// **'Signup failed'**
  String get settingsSignupFailed;

  /// No description provided for @userProfileCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get userProfileCompany;

  /// No description provided for @userProfileLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get userProfileLoading;

  /// No description provided for @userProfileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get userProfileUpdatedSuccess;

  /// No description provided for @userProfileUserIdMissing.
  ///
  /// In en, this message translates to:
  /// **'User ID is missing'**
  String get userProfileUserIdMissing;

  /// No description provided for @userProfileFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{fieldLabel} is required.'**
  String userProfileFieldRequired(Object fieldLabel);

  /// No description provided for @userProfileFieldInvalidInteger.
  ///
  /// In en, this message translates to:
  /// **'{fieldLabel} must be a valid integer.'**
  String userProfileFieldInvalidInteger(Object fieldLabel);

  /// No description provided for @userEditUserIdMissing.
  ///
  /// In en, this message translates to:
  /// **'User ID is missing'**
  String get userEditUserIdMissing;

  /// No description provided for @userEditProfileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get userEditProfileUpdatedSuccess;

  /// No description provided for @companyProfileCompanyLogo.
  ///
  /// In en, this message translates to:
  /// **'Company Logo'**
  String get companyProfileCompanyLogo;

  /// No description provided for @companyProfileSelectLogo.
  ///
  /// In en, this message translates to:
  /// **'Select company logo'**
  String get companyProfileSelectLogo;

  /// No description provided for @companyProfileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Company profile updated successfully'**
  String get companyProfileUpdatedSuccess;

  /// No description provided for @companyProfileCompanyIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Company ID is missing'**
  String get companyProfileCompanyIdMissing;

  /// No description provided for @companyProfileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get companyProfileNameRequired;

  /// No description provided for @companyProfileLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Location is required'**
  String get companyProfileLocationRequired;

  /// No description provided for @companyEditLogo.
  ///
  /// In en, this message translates to:
  /// **'Company Logo'**
  String get companyEditLogo;

  /// No description provided for @companyEditLogoPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select company logo'**
  String get companyEditLogoPlaceholder;

  /// No description provided for @companyEditCompanyIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Company ID is missing'**
  String get companyEditCompanyIdMissing;

  /// No description provided for @companyEditProfileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Company profile updated successfully'**
  String get companyEditProfileUpdatedSuccess;

  /// No description provided for @staffManagementUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get staffManagementUserNotFound;

  /// No description provided for @staffManagementFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{fieldLabel} is required.'**
  String staffManagementFieldRequired(Object fieldLabel);

  /// No description provided for @imageGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String imageGalleryTitle(Object current, Object total);

  /// No description provided for @commonNA.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get commonNA;

  /// No description provided for @commonBy.
  ///
  /// In en, this message translates to:
  /// **'By'**
  String get commonBy;

  /// No description provided for @commonNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get commonNotAssigned;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @commonOK.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOK;

  /// No description provided for @commonEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get commonEnglish;

  /// No description provided for @commonRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get commonRussian;

  /// No description provided for @commonKazakh.
  ///
  /// In en, this message translates to:
  /// **'Қазақша'**
  String get commonKazakh;
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
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
