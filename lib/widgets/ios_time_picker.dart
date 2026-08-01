import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<TimeOfDay?> showIosTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) async {
  var selectedDateTime = DateTime(
    2026,
    1,
    1,
    initialTime.hour,
    initialTime.minute,
  );

  return showCupertinoModalPopup<TimeOfDay>(
    context: context,
    builder: (popupContext) {
      final colorScheme = Theme.of(context).colorScheme;

      return Material(
        color: Colors.transparent,
        child: Container(
          height: 330,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(popupContext);
                        },
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(
                            popupContext,
                            TimeOfDay(
                              hour: selectedDateTime.hour,
                              minute: selectedDateTime.minute,
                            ),
                          );
                        },
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness: Theme.of(context).brightness,
                      textTheme: const CupertinoTextThemeData(
                        dateTimePickerTextStyle: TextStyle(fontSize: 22),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: selectedDateTime,
                      use24hFormat: false,
                      minuteInterval: 5,
                      onDateTimeChanged: (value) {
                        selectedDateTime = value;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
