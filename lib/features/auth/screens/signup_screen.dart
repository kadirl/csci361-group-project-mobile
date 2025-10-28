import 'package:flutter/material.dart';
import 'package:swe_mobile/l10n/app_localizations.dart';

// Signup screen with stepper
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _currentStep = 0;

  List<Step> stepList() => [
    const Step(
      title: Text('Аккаунт владельца'), 
      content: Center(child: Text('Account'),)),
    const Step(title: Text('Аккаунт компании'), content: Center(child: Text('Address'),)),
  ];

  @override
  Widget build(BuildContext context) {
    // Get localized strings
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signUp),
      ),
      body: SafeArea(
        child: Stepper(
          type: StepperType.horizontal,
          steps: stepList(),
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < stepList().length - 1) {
              setState(() {
                _currentStep++;
              });
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep--;
              });
            } else {
              Navigator.pop(context);
            }
          },
          controlsBuilder: (context, details) {
            return Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: details.onStepCancel, 
                    child: const Text('Back'),
                  ),
                ),

                const SizedBox(width: 12),
                
                Expanded(
                  child: FilledButton(
                    onPressed: details.onStepContinue, 
                    child: const Text('Continue'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
