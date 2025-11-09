import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swe_mobile/core/constants/button_sizes.dart';
import 'package:swe_mobile/l10n/app_localizations.dart';
import 'package:path/path.dart' as path;
import 'signup_viewmodel.dart';

// Signup screen with stepper
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
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
  
  // Manage text input and selections for the business information step
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyDescriptionController = TextEditingController();

  // Manage image selection from gallery or camera
  final ImagePicker _imagePicker = ImagePicker();
  
  // Formatter to enforce "+7 707 707 7777" phone number structure
  static const List<TextInputFormatter> _phoneNumberFormatters = [
    PhoneNumberFormatter(),
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

  // Validate the form belonging to the provided step index
  bool _validateStep(int stepIndex) {
    final FormState? formState = _stepFormKeys[stepIndex].currentState;

    if (formState == null) {
      return true;
    }

    return formState.validate();
  }

  // Confirm that each step between the current position and the target is valid
  bool _canAdvanceToStep({
    required int fromStep,
    required int toStep,
  }) {
    for (int stepIndex = fromStep; stepIndex < toStep; stepIndex++) {
      final bool isStepValid = _validateStep(stepIndex);

      if (!isStepValid) {
        return false;
      }
    }

    return true;
  }

  // Build the list of steps using the latest view-model state
  List<Step> _buildSteps({
    required AppLocalizations l10n,
    required SignupState signupState,
    required SignupViewModel signupViewModel,
  }) {
    return [
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
                  validator: (value) => SignupValidators.validateRequiredField(
                    value,
                    l10n.signupStep2FirstName,
                  ),
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
                  validator: (value) => SignupValidators.validateRequiredField(
                    value,
                    l10n.signupStep2LastName,
                  ),
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
                  validator: (value) => SignupValidators.validatePhoneNumber(
                    value,
                    l10n.signupStep2PhoneNumber,
                  ),
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
                  validator: (value) => SignupValidators.validateEmail(
                    value,
                    l10n.signupStep2Email,
                  ),
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
                  obscureText: !signupState.isPasswordVisible,
                  validator: (value) => SignupValidators.validateRequiredField(
                    value,
                    l10n.signupStep2Password,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.signupStep2Password,
                    hintText: l10n.signupStep2passwordPlaceholder,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        signupState.isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        signupViewModel.togglePasswordVisibility();
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
                    groupValue: signupState.selectedCompanyType,
                    onChanged: (int? value) {
                      if (value != null) {
                        signupViewModel.setCompanyType(value);
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
                  validator: (value) => SignupValidators.validateRequiredField(
                    value,
                    l10n.signupStep3Name,
                  ),
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
                  validator: (value) => SignupValidators.validateRequiredField(
                    value,
                    l10n.signupStep3Description,
                  ),
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
                    await signupViewModel.pickLogo(
                      imagePicker: _imagePicker,
                    );
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.signupStep3Logo,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.file_upload),
                    ),
                    child: Text(
                      signupState.logoFilePath == null
                          ? l10n.signupStep3LogoPlaceholder
                          : path.basename(signupState.logoFilePath!),
                      style: TextStyle(
                        color: signupState.logoFilePath == null
                            ? Colors.grey
                            : null,
                      ),
                    ),
                  ),
                ),

                if (signupState.logoPreviewBytes != null) ...[
                  const SizedBox(height: 12),

                  // Display a preview of the selected logo file
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        signupState.logoPreviewBytes!,
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
                  initialValue: signupState.selectedCity,
                  decoration: InputDecoration(
                    labelText: l10n.signupStep3Location,
                    border: const OutlineInputBorder(),
                  ),
                  hint: Text(l10n.signupStep3LocationPlaceholder),
                  items: signupState.cityOptions.map((String city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  validator: (value) => SignupValidators.validateRequiredField(
                    value,
                    l10n.signupStep3Location,
                  ),
                  onChanged: (String? newValue) {
                    signupViewModel.setSelectedCity(newValue);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Get localized strings
    final l10n = AppLocalizations.of(context)!;

    // Watch the current signup state
    final signupState = ref.watch(signupViewModelProvider);

    // Read the view-model instance to trigger mutations
    final signupViewModel = ref.read(signupViewModelProvider.notifier);

    // Prepare steps once to keep references consistent during this build cycle
    final List<Step> steps = _buildSteps(
      l10n: l10n,
      signupState: signupState,
      signupViewModel: signupViewModel,
    );

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
                currentStep: signupState.currentStep,
                onStepTapped: (int index) {
                  if (index == signupState.currentStep) {
                    return;
                  }

                  if (index > signupState.currentStep) {
                    final bool canAdvance = _canAdvanceToStep(
                      fromStep: signupState.currentStep,
                      toStep: index,
                    );

                    if (!canAdvance) {
                      return;
                    }
                  }

                  signupViewModel.jumpToStep(index);
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
                        if (signupState.currentStep < steps.length - 1) {
                          // Validate the current step before advancing
                          final bool isCurrentStepValid = _validateStep(signupState.currentStep);

                          if (isCurrentStepValid) {
                            signupViewModel.goToNextStep();
                          }
                        } else {
                          // On last step, ensure the final step validates before submission
                          final bool isFinalStepValid = _validateStep(signupState.currentStep);

                          if (isFinalStepValid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Form submitted!')),
                            );
                            // TODO: Add your form submission logic here
                          }
                        }
                      },
                      child: Text(
                          signupState.currentStep < steps.length - 1 ? l10n.commonNext : l10n.commonSubmit,
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
                        if (signupState.currentStep > 0) {
                          // Go back to previous step
                          signupViewModel.goToPreviousStep();
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