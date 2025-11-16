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
  String get signUp => 'Create a Company';

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

  @override
  String get signupTitle => 'Create a Company';

  @override
  String get signupStep1Title => 'Company Type';

  @override
  String get signupStep1Consumer => 'Consumer';

  @override
  String get signupStep1Supplier => 'Supplier';

  @override
  String get signupStep2Title => 'Owner Details';

  @override
  String get signupStep2FirstName => 'First name';

  @override
  String get signupStep2FirstNamePlaceholder => 'Please enter your first name';

  @override
  String get signupStep2LastName => 'Last name';

  @override
  String get signupStep2LastNamePlaceholder => 'Please enter your last name';

  @override
  String get signupStep2PhoneNumber => 'Phone number';

  @override
  String get signupStep2PhoneNumberPlaceholder => '+7-000-000-00-00';

  @override
  String get signupStep2Email => 'Email';

  @override
  String get signupStep2EmailPlaceholder => 'example@mail.com';

  @override
  String get signupStep2Password => 'Password';

  @override
  String get signupStep2passwordPlaceholder => 'Enter your password';

  @override
  String get signupStep2passwordRequired => 'Please enter your password';

  @override
  String get signupStep3Title => 'Company Details';

  @override
  String get signupStep3Name => 'Company name';

  @override
  String get signupStep3NamePlaceholder => 'Enter company name';

  @override
  String get signupStep3Description => 'Description';

  @override
  String get signupStep3DescriptionPlaceholder => 'Enter company description';

  @override
  String get signupStep3Logo => 'Company logo';

  @override
  String get signupStep3LogoPlaceholder => 'Select logo file';

  @override
  String get signupStep3Location => 'Location';

  @override
  String get signupStep3LocationPlaceholder => 'Select city';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonBackToLogin => 'Back to sign in';

  @override
  String get errorLoadingCitiesTitle => 'Unable to load cities';

  @override
  String get settingsUserProfile => 'User profile';

  @override
  String get settingsCompanyProfile => 'Company profile';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get userProfileTitle => 'User profile';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get userRole => 'Role';

  @override
  String get userLocale => 'Locale';

  @override
  String get companyLabel => 'Company';

  @override
  String get refreshProfile => 'Refresh profile';

  @override
  String get errorLoadingProfile => 'Failed to load profile';

  @override
  String get noUserProfile => 'No user profile available';

  @override
  String get companyProfileTitle => 'Company profile';

  @override
  String get companyName => 'Name';

  @override
  String get companyLocation => 'Location';

  @override
  String get companyType => 'Type';

  @override
  String get companyDescription => 'Description';

  @override
  String get companyId => 'Company ID';

  @override
  String get refreshCompany => 'Refresh company';

  @override
  String get errorLoadingCompany => 'Failed to load company';

  @override
  String get noCompanyProfile => 'No company profile available';

  @override
  String get companyTypeSupplier => 'Supplier';

  @override
  String get companyTypeConsumer => 'Consumer';

  @override
  String get settingsStaffManagement => 'Staff Management';

  @override
  String get staffManagementTitle => 'Staff Management';

  @override
  String get catalogCreateProductTitle => 'Create product';

  @override
  String get catalogProductNameLabel => 'Name';

  @override
  String get catalogProductDescriptionLabel => 'Description';

  @override
  String get catalogProductStockQuantityLabel => 'Stock quantity';

  @override
  String get catalogProductRetailPriceLabel => 'Retail price';

  @override
  String get catalogProductThresholdLabel => 'Threshold';

  @override
  String get catalogProductBulkPriceLabel => 'Bulk price';

  @override
  String get catalogProductMinimumOrderLabel => 'Minimum order';

  @override
  String get catalogProductUnitLabel => 'Unit';

  @override
  String get catalogCreateProductSuccess => 'Product created successfully';

  @override
  String catalogCreateProductErrorGeneric(Object error) {
    return 'Failed to create product: $error';
  }
}
