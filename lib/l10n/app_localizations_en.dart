// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SWE Mobile';

  @override
  String get welcome => 'Welcome';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get email => 'Email';

  @override
  String get emailPlaceholder => 'Enter your email';

  @override
  String get emailRequired => 'Please enter your email';

  @override
  String get password => 'Password';

  @override
  String get passwordPlaceholder => 'Enter your password';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get logout => 'Logout';

  @override
  String get home => 'Home';

  @override
  String get search => 'Search';

  @override
  String get add => 'Add';

  @override
  String get notifications => 'Notifications';

  @override
  String get profile => 'Profile';

  @override
  String get emailAndPasswordRequired => 'Email and password are required';
}
