import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_select_field.dart';
import '../calendar_helpers.dart';

class MonthYearPickerDialog extends StatefulWidget {
  const MonthYearPickerDialog({required this.initialMonth, super.key});

  final DateTime initialMonth;

  @override
  State<MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<MonthYearPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();

    _selectedYear = widget.initialMonth.year;
    _selectedMonth = widget.initialMonth.month;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    final availableYears = [
      for (var year = currentYear - 100; year <= currentYear + 10; year++) year,
    ];

    return AlertDialog(
      title: const Text('Choose month'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSelectField<int>(
              value: _selectedYear,
              values: availableYears,
              label: 'Year',
              labelBuilder: (value) => '$value',
              onChanged: (value) {
                setState(() {
                  _selectedYear = value;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;

                return ChoiceChip(
                  label: Text(shortMonthName(month)),
                  selected: _selectedMonth == month,
                  onSelected: (_) {
                    setState(() {
                      _selectedMonth = month;
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, DateTime(_selectedYear, _selectedMonth));
          },
          child: const Text('Go'),
        ),
      ],
    );
  }
}
