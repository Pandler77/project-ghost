import 'package:flutter/material.dart';

class WizardButtons extends StatelessWidget {
  const WizardButtons({
    required this.onNext,
    this.onBack,
    this.nextLabel = 'Next',
    this.isNextEnabled = true,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback? onBack;
  final VoidCallback onNext;

  final String nextLabel;
  final bool isNextEnabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: isLoading ? null : onBack,
              child: const Text('Back'),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: FilledButton(
            onPressed: isNextEnabled && !isLoading ? onNext : null,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(nextLabel),
          ),
        ),
      ],
    );
  }
}
