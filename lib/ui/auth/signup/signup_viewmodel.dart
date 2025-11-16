import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swe_mobile/core/providers/auth_provider.dart';
import 'package:swe_mobile/data/models/auth_models.dart';

// Result type for a signup attempt
@immutable
class SignupResult {
  const SignupResult({required this.success, this.errorMessage});
  final bool success;
  final String? errorMessage;
}


// Immutable state that represents all signup form data
@immutable
class SignupState {
  const SignupState({
    required this.currentStep,
    required this.selectedCompanyType,
    required this.isPasswordVisible,
    required this.selectedCity,
    required this.logoFilePath,
    required this.logoPreviewBytes,
  });

  final int currentStep;
  final int selectedCompanyType;
  final bool isPasswordVisible;
  final String? selectedCity;
  final String? logoFilePath;
  final Uint8List? logoPreviewBytes;

  // Create a new state instance with updated values
  SignupState copyWith({
    int? currentStep,
    int? selectedCompanyType,
    bool? isPasswordVisible,
    String? selectedCity,
    String? logoFilePath,
    Uint8List? logoPreviewBytes,
  }) {
    return SignupState(
      currentStep: currentStep ?? this.currentStep,
      selectedCompanyType: selectedCompanyType ?? this.selectedCompanyType,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      selectedCity: selectedCity ?? this.selectedCity,
      logoFilePath: logoFilePath ?? this.logoFilePath,
      logoPreviewBytes: logoPreviewBytes ?? this.logoPreviewBytes,
    );
  }
}

// View-model that encapsulates the signup screen business logic
class SignupViewModel extends Notifier<SignupState> {
  @override
  SignupState build() {
    return const SignupState(
      currentStep: 0,
      selectedCompanyType: 0,
      isPasswordVisible: false,
      selectedCity: null,
      logoFilePath: null,
      logoPreviewBytes: null,
    );
  }

  // Toggle the password field visibility flag
  void togglePasswordVisibility() {
    state = state.copyWith(
      isPasswordVisible: !state.isPasswordVisible,
    );
  }

  // Change the current step directly
  void jumpToStep(int targetStep) {
    state = state.copyWith(currentStep: targetStep);
  }

  // Advance to the next step in the flow
  void goToNextStep() {
    state = state.copyWith(currentStep: state.currentStep + 1);
  }

  // Return to the previous step in the flow
  void goToPreviousStep() {
    state = state.copyWith(currentStep: state.currentStep - 1);
  }

  // Persist the selected company type
  void setCompanyType(int companyType) {
    state = state.copyWith(selectedCompanyType: companyType);
  }

  // Persist the selected city
  void setSelectedCity(String? city) {
    state = state.copyWith(selectedCity: city);
  }

  // Store the selected logo file metadata and preview bytes
  void setLogoPreview({
    required String? path,
    required Uint8List? bytes,
  }) {
    state = state.copyWith(
      logoFilePath: path,
      logoPreviewBytes: bytes,
    );
  }

  // Helper to trigger the image picker and save the selection
  Future<void> pickLogo({
    required ImagePicker imagePicker,
  }) async {
    final XFile? pickedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (pickedImage == null) {
      return;
    }

    final Uint8List logoBytes = await pickedImage.readAsBytes();

    setLogoPreview(
      path: pickedImage.path,
      bytes: logoBytes,
    );
  }

  // Submit signup by mapping the current form inputs to an API request
  Future<SignupResult> submitSignup({
    required String firstName,
    required String lastName,
    required String phoneNumberFormatted,
    required String email,
    required String password,
    required String companyName,
    String? companyDescription,
    required String? selectedCity,
    required int selectedCompanyTypeIndex, // 0 = consumer, 1 = supplier
    required String localeCode,
    String? logoPath,
  }) async {
    // Normalize phone number to digits only
    final String phoneDigits =
        phoneNumberFormatted.replaceAll(RegExp(r'\D'), '');

    // Map radio index to backend company type
    final String companyType =
        selectedCompanyTypeIndex == 0 ? 'consumer' : 'supplier';

    // Build request DTOs for company and user
    final RegisterCompanyCompany company = RegisterCompanyCompany(
      name: companyName.trim(),
      location: selectedCity ?? '',
      companyType: companyType,
      description: (companyDescription?.trim().isEmpty ?? true)
          ? null
          : companyDescription!.trim(),
      // NOTE: Logo upload not implemented; send path as-is for now
      logoUrl: logoPath,
    );

    final RegisterCompanyUser user = RegisterCompanyUser(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      phoneNumber: phoneDigits,
      email: email.trim(),
      password: password,
      // Register flow creates the company owner
      role: 'owner',
      locale: localeCode,
    );

    final RegisterCompanyRequest request =
        RegisterCompanyRequest(company: company, user: user);

    // Call the auth provider to perform signup and update global auth state
    try {
      await ref.read(authProvider.notifier).signUp(request: request);
    } catch (e) {
      // In case any unexpected throw bypassed state setting
      return SignupResult(success: false, errorMessage: e.toString());
    }

    // Read updated auth state to determine success
    final AuthState authState = ref.read(authProvider);

    if (authState.isAuthenticated && authState.error == null) {
      return const SignupResult(success: true);
    }

    return SignupResult(
      success: false,
      errorMessage: authState.error ?? 'Signup failed',
    );
  }
}

// Collection of reusable signup form validators
class SignupValidators {
  const SignupValidators._();

  // Validate that a field is not empty
  static String? validateRequiredField(String? value, String fieldLabel) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldLabel is required.';
    }

    return null;
  }

  // Validate that a field contains a valid email
  static String? validateEmail(String? value, String fieldLabel) {
    final String? requiredValidation =
        validateRequiredField(value, fieldLabel);

    if (requiredValidation != null) {
      return requiredValidation;
    }

    final RegExp emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

    if (!emailPattern.hasMatch(value!.trim())) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  // Validate that a phone number contains the required number of digits
  static String? validatePhoneNumber(String? value, String fieldLabel) {
    final String? requiredValidation =
        validateRequiredField(value, fieldLabel);

    if (requiredValidation != null) {
      return requiredValidation;
    }

    final String digitsOnly = value!.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length != 11) {
      return 'Please enter a complete phone number.';
    }

    return null;
  }
}

// Riverpod provider that exposes the signup view-model
final signupViewModelProvider =
    NotifierProvider<SignupViewModel, SignupState>(
  SignupViewModel.new,
);

// Formatter to enforce the "+7 707 707 7777" structure across the app
class PhoneNumberFormatter extends TextInputFormatter {
  const PhoneNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (!digitsOnly.startsWith('7')) {
      digitsOnly = '7${digitsOnly.replaceFirst(RegExp(r'^7'), '')}';
    }

    if (digitsOnly.length > 11) {
      digitsOnly = digitsOnly.substring(0, 11);
    }

    final String localDigits =
        digitsOnly.length > 1 ? digitsOnly.substring(1) : '';

    final StringBuffer formatted = StringBuffer('+7');

    if (localDigits.isNotEmpty) {
      formatted.write(' ');
      formatted.write(localDigits.substring(0, math.min(3, localDigits.length)));
    }

    if (localDigits.length > 3) {
      formatted.write(' ');
      formatted.write(localDigits.substring(3, math.min(6, localDigits.length)));
    }

    if (localDigits.length > 6) {
      formatted.write(' ');
      formatted.write(localDigits.substring(6, math.min(10, localDigits.length)));
    }

    final String formattedText = formatted.toString();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

