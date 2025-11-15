import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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
