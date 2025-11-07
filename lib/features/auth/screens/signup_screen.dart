import 'package:flutter/material.dart';
import 'package:swe_mobile/l10n/app_localizations.dart';
import 'package:swe_mobile/core/constants/button_sizes.dart';

// Signup screen with stepper
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _currentStep = 0;
  int _selectedCompanyType = 0;
  
  // Form controllers for step 2
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  
  // Form controllers for step 3
  final _companyNameController = TextEditingController();
  final _companyDescriptionController = TextEditingController();
  String? _selectedCity;
  String? _logoFilePath;
  
  // Placeholder cities list
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

  List<Step> stepList(AppLocalizations l10n) => [
    Step(
      title: Text(l10n.signupStep1Title),
      content: Center(
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
    ),

    Step(
      title: Text(l10n.signupStep2Title),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: [
            // First Name
            TextFormField(
              controller: _firstNameController,
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

    Step(
      title: Text(l10n.signupStep3Title),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: [
            // Company Name
            TextFormField(
              controller: _companyNameController,
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
                // TODO: Implement file picker
                // For now, just show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File picker not implemented yet')),
                );
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.signupStep3Logo,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.file_upload),
                ),
                child: Text(
                  _logoFilePath ?? l10n.signupStep3LogoPlaceholder,
                  style: TextStyle(
                    color: _logoFilePath == null ? Colors.grey : null,
                  ),
                ),
              ),
            ),
            
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
  ];

  @override
  Widget build(BuildContext context) {
    // Get localized strings
    final l10n = AppLocalizations.of(context)!;

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
                steps: stepList(l10n),
                currentStep: _currentStep,
                onStepTapped: (int index) {
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
                        if (_currentStep < stepList(l10n).length - 1) {
                          // Not on last step, advance to next step
                          setState(() {
                            _currentStep++;
                          });
                        } else {
                          // On last step, submit the form
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Form submitted!')),
                          );
                          // TODO: Add your form submission logic here
                        }
                      },
                      child: Text(
                        _currentStep < stepList(l10n).length - 1 ? l10n.commonNext : l10n.commonSubmit,
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
