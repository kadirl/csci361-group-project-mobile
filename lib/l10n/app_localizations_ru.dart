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
}
