import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swe_mobile/core/constants/button_sizes.dart';
import 'package:swe_mobile/l10n/app_localizations.dart';
import 'package:path/path.dart' as path;

// Signup screen with stepper
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Track the current step within the Stepper flow
  int _currentStep = 0;

  // Track the selected company type option
  int _selectedCompanyType = 0;

  // Keep each step's form state isolated for validation
  final List<GlobalKey<FormState>> _stepFormKeys = List<GlobalKey<FormState>>.generate(
    2,
    (_) => GlobalKey<FormState>(),
  );
  
  // Manage text input for the personal information step
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Toggle the visibility of the password field
  bool _isPasswordVisible = false;
  
  // Manage text input and selections for the business information step
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyDescriptionController = TextEditingController();
  String? _selectedCity;
  String? _logoFilePath;
  Uint8List? _logoPreviewBytes;

  // Manage image selection from gallery or camera
  final ImagePicker _imagePicker = ImagePicker();
  
  // Formatter to enforce "+7 707 707 7777" phone number structure
  static const List<TextInputFormatter> _phoneNumberFormatters = [
    _PhoneNumberFormatter(),
  ];
  
  // Provide available city options for the dropdown
  final List<String> _cities = [
    'Astana',
    'Almaty',
    'Shymkent',
    'Karaganda',
    'Aktobe',
    'Taraz',
    'Pavlodar',
    'Ust-Kamenogorsk',
    'Semey',
    'Atyrau',
  ];
  
  // Initialize default values for the form controllers
  @override
  void initState() {
    super.initState();

    _phoneNumberController.text = '+7';
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _companyNameController.dispose();
    _companyDescriptionController.dispose();
    super.dispose();
  }

  // Validator helper to enforce required fields
  String? _validateRequiredField(String? value, String fieldLabel) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldLabel is required.';
    }

    return null;
  }

  // Validator helper to perform a minimal email check
  String? _validateEmail(String? value, String fieldLabel) {
    final String? requiredValidation = _validateRequiredField(value, fieldLabel);

    if (requiredValidation != null) {
      return requiredValidation;
    }

    final RegExp emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

    if (!emailPattern.hasMatch(value!.trim())) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  // Validator helper to ensure the phone number contains all required digits
  String? _validatePhoneNumber(String? value, String fieldLabel) {
    final String? requiredValidation = _validateRequiredField(value, fieldLabel);

    if (requiredValidation != null) {
      return requiredValidation;
    }

    final String digitsOnly = value!.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length != 11) {
      return 'Please enter a complete phone number.';
    }

    return null;
  }

  // Validate the form belonging to the provided step index
  bool _validateStep(int stepIndex) {
    final FormState? formState = _stepFormKeys[stepIndex].currentState;

    if (formState == null) {
      return true;
    }

    return formState.validate();
  }

  // Confirm that each step between the current position and the target is valid
  bool _canAdvanceToStep(int targetStep) {
    for (int stepIndex = _currentStep; stepIndex < targetStep; stepIndex++) {
      final bool isStepValid = _validateStep(stepIndex);

      if (!isStepValid) {
        return false;
      }
    }

    return true;
  }

  List<Step> stepList(AppLocalizations l10n) => [
    Step(
      title: Text(l10n.signupStep2Title),
      content: Form(
        key: _stepFormKeys[0],
        autovalidateMode: AutovalidateMode.onUnfocus,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              // First Name
              TextFormField(
                controller: _firstNameController,
                validator: (value) => _validateRequiredField(value, l10n.signupStep2FirstName),
                decoration: InputDecoration(
                  labelText: l10n.signupStep2FirstName,
                  hintText: l10n.signupStep2FirstNamePlaceholder,
                  border: const OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Last Name
              TextFormField(
                controller: _lastNameController,
                validator: (value) => _validateRequiredField(value, l10n.signupStep2LastName),
                decoration: InputDecoration(
                  labelText: l10n.signupStep2LastName,
                  hintText: l10n.signupStep2LastNamePlaceholder,
                  border: const OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Phone Number
              TextFormField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                inputFormatters: _phoneNumberFormatters,
                validator: (value) => _validatePhoneNumber(value, l10n.signupStep2PhoneNumber),
                decoration: InputDecoration(
                  labelText: l10n.signupStep2PhoneNumber,
                  hintText: l10n.signupStep2PhoneNumberPlaceholder,
                  border: const OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) => _validateEmail(value, l10n.signupStep2Email),
                decoration: InputDecoration(
                  labelText: l10n.signupStep2Email,
                  hintText: l10n.signupStep2EmailPlaceholder,
                  border: const OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                validator: (value) => _validateRequiredField(value, l10n.signupStep2Password),
                decoration: InputDecoration(
                  labelText: l10n.signupStep2Password,
                  hintText: l10n.signupStep2passwordPlaceholder,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),

    Step(
      title: Text(l10n.signupStep3Title),
      content: Form(
        key: _stepFormKeys[1],
        autovalidateMode: AutovalidateMode.onUnfocus,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              // Select the company type
              Align(
                alignment: Alignment.centerLeft,
                child: RadioGroup<int>(
                  groupValue: _selectedCompanyType,
                  onChanged: (int? value) {
                    if (value != null) {
                      setState(() {
                        _selectedCompanyType = value;
                      });
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<int>(
                        title: Text(l10n.signupStep1Consumer),
                        value: 0,
                      ),
                      RadioListTile<int>(
                        title: Text(l10n.signupStep1Supplier),
                        value: 1,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Company Name
              TextFormField(
                controller: _companyNameController,
                validator: (value) => _validateRequiredField(value, l10n.signupStep3Name),
                decoration: InputDecoration(
                  labelText: l10n.signupStep3Name,
                  hintText: l10n.signupStep3NamePlaceholder,
                  border: const OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Company Description
              TextFormField(
                controller: _companyDescriptionController,
                maxLines: 3,
                validator: (value) => _validateRequiredField(value, l10n.signupStep3Description),
                decoration: InputDecoration(
                  labelText: l10n.signupStep3Description,
                  hintText: l10n.signupStep3DescriptionPlaceholder,
                  border: const OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Logo File Selector
              InkWell(
                onTap: () async {
                  // Prompt the user to pick an image from the gallery
                  final XFile? pickedImage = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1024,
                    maxHeight: 1024,
                  );

                  // Update the selected image path when the user picks one
                  if (pickedImage == null) {
                    return;
                  }

                  final Uint8List logoBytes = await pickedImage.readAsBytes();

                  setState(() {
                    _logoFilePath = pickedImage.path;
                    _logoPreviewBytes = logoBytes;
                  });
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.signupStep3Logo,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.file_upload),
                  ),
                  child: Text(
                    _logoFilePath == null ? l10n.signupStep3LogoPlaceholder : path.basename(_logoFilePath!),
                    style: TextStyle(
                      color: _logoFilePath == null ? Colors.grey : null,
                    ),
                  ),
                ),
              ),

              if (_logoPreviewBytes != null) ...[
                const SizedBox(height: 12),

                // Display a preview of the selected logo file
                Align(
                  alignment: Alignment.centerLeft,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _logoPreviewBytes!,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Location Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCity,
                decoration: InputDecoration(
                  labelText: l10n.signupStep3Location,
                  border: const OutlineInputBorder(),
                ),
                hint: Text(l10n.signupStep3LocationPlaceholder),
                items: _cities.map((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Text(city),
                  );
                }).toList(),
                validator: (value) => _validateRequiredField(value, l10n.signupStep3Location),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCity = newValue;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Get localized strings
    final l10n = AppLocalizations.of(context)!;
    
    // Prepare steps once to keep references consistent during this build cycle
    final List<Step> steps = stepList(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signupTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stepper(
                type: StepperType.vertical,
                steps: steps,
                currentStep: _currentStep,
                onStepTapped: (int index) {
                  if (index == _currentStep) {
                    return;
                  }

                  if (index > _currentStep) {
                    final bool canAdvance = _canAdvanceToStep(index);

                    if (!canAdvance) {
                      return;
                    }
                  }

                  setState(() {
                    _currentStep = index;
                  });
                },
                controlsBuilder: (context, details) {
                  // Return empty container to hide the default buttons
                  return const SizedBox.shrink();
                },
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                    SizedBox(
                      width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: ButtonSizes.mdFill,
                      ),
                      onPressed: () {
                        if (_currentStep < steps.length - 1) {
                          // Validate the current step before advancing
                          final bool isCurrentStepValid = _validateStep(_currentStep);

                          if (isCurrentStepValid) {
                            setState(() {
                              _currentStep++;
                            });
                          }
                        } else {
                          // On last step, ensure the final step validates before submission
                          final bool isFinalStepValid = _validateStep(_currentStep);

                          if (isFinalStepValid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Form submitted!')),
                            );
                            // TODO: Add your form submission logic here
                          }
                        }
                      },
                      child: Text(
                          _currentStep < steps.length - 1 ? l10n.commonNext : l10n.commonSubmit,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        minimumSize: ButtonSizes.mdFill,
                      ),
                      onPressed: () {
                        if (_currentStep > 0) {
                          // Go back to previous step
                          setState(() {
                            _currentStep--;
                          });
                        } else {
                          // On first step, pop the screen
                          Navigator.pop(context);
                        }
                      },
                      child: Text(l10n.commonBack),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom phone number formatter for Kazakh numbers
class _PhoneNumberFormatter extends TextInputFormatter {
  const _PhoneNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Extract only digits to normalize the input
    String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Ensure the value always starts with the country code digit "7"
    if (!digitsOnly.startsWith('7')) {
      digitsOnly = '7${digitsOnly.replaceFirst(RegExp(r'^7'), '')}';
    }

    // Limit input to country code plus 10 digits
    if (digitsOnly.length > 11) {
      digitsOnly = digitsOnly.substring(0, 11);
    }

    // Remove the leading country code digit to format the rest
    final String localDigits = digitsOnly.length > 1 ? digitsOnly.substring(1) : '';

    // Prepare the formatted output starting with "+7"
    final StringBuffer formatted = StringBuffer('+7');

    if (localDigits.isNotEmpty) {
      // Append the first block of three digits
      formatted.write(' ');
      formatted.write(localDigits.substring(0, math.min(3, localDigits.length)));
    }

    if (localDigits.length > 3) {
      // Append the second block of three digits
      formatted.write(' ');
      formatted.write(localDigits.substring(3, math.min(6, localDigits.length)));
    }

    if (localDigits.length > 6) {
      // Append the final block of up to four digits
      formatted.write(' ');
      formatted.write(localDigits.substring(6, math.min(10, localDigits.length)));
    }

    final String formattedText = formatted.toString();

    return TextEditingValue(
      text: formattedText,
      // Collapse the cursor to the end of the formatted input
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
