// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'APP';

  @override
  String get welcome => 'Добро пожаловать!';

  @override
  String get signInToContinue => 'Войдите чтобы продолжить';

  @override
  String get email => 'Электронная почта';

  @override
  String get emailPlaceholder => 'Введите вашу электронную почту';

  @override
  String get emailRequired => 'Пожалуйста, введите электронную почту';

  @override
  String get password => 'Пароль';

  @override
  String get passwordPlaceholder => 'Введите пароль';

  @override
  String get passwordRequired => 'Пожалуйста, введите пароль';

  @override
  String get signIn => 'Войти';

  @override
  String get signUp => 'Создать компанию';

  @override
  String get logout => 'Выйти';

  @override
  String get home => 'Главная';

  @override
  String get search => 'Поиск';

  @override
  String get add => 'Добавить';

  @override
  String get notifications => 'Уведомления';

  @override
  String get profile => 'Профиль';

  @override
  String get emailAndPasswordRequired => 'Требуется электронная почта и пароль';

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
  String get companyType => 'Тип компании';

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
  String get companyTypeSupplier => 'Поставщик';

  @override
  String get companyTypeConsumer => 'Потребитель';

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
  String get catalogProductImagesLabel => 'Product images';

  @override
  String get catalogProductImagesPlaceholder =>
      'Select product images (up to 5)';

  @override
  String get catalogProductImagesMaxExceededTitle => 'Maximum images reached';

  @override
  String get catalogProductImagesMaxExceededMessage =>
      'You can only add up to 5 images. Some images were not added.';

  @override
  String get catalogCreateProductSuccess => 'Product created successfully';

  @override
  String catalogCreateProductErrorGeneric(Object error) {
    return 'Failed to create product: $error';
  }

  @override
  String get catalogEditProductTitle => 'Edit product';

  @override
  String get catalogUpdateProductSuccess => 'Product updated successfully';

  @override
  String catalogUpdateProductErrorGeneric(Object error) {
    return 'Failed to update product: $error';
  }

  @override
  String get catalogDeleteProductTitle => 'Delete product';

  @override
  String get catalogDeleteProductMessage =>
      'Are you sure you want to delete this product? This action cannot be undone.';

  @override
  String get catalogDeleteProductSuccess => 'Product deleted successfully';

  @override
  String catalogDeleteProductErrorGeneric(Object error) {
    return 'Failed to delete product: $error';
  }

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get staffCreateUserSuccess => 'User created successfully';

  @override
  String get staffDeleteUserTitle => 'Delete user';

  @override
  String get staffDeleteUserMessage =>
      'Are you sure you want to delete this user? This action cannot be undone.';

  @override
  String get staffDeleteUserSuccess => 'User deleted successfully';

  @override
  String staffDeleteUserErrorGeneric(Object error) {
    return 'Failed to delete user: $error';
  }
}
