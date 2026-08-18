String unrecordedStatusText(DateTime date) {
  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);

  final selectedDate = DateTime(date.year, date.month, date.day);

  if (selectedDate.isBefore(today)) {
    return 'Not recorded';
  }

  if (isSameDay(selectedDate, today)) {
    return 'Pending';
  }

  return 'Scheduled';
}

String scheduleCountText(int count) {
  return count == 1 ? '1 protocol scheduled' : '$count protocols scheduled';
}

String formatMonthYear(DateTime date) {
  return '${monthName(date.month)} ${date.year}';
}

String formatSelectedDate(DateTime date) {
  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);

  final yesterday = today.subtract(const Duration(days: 1));

  final tomorrow = today.add(const Duration(days: 1));

  final fullDate = formatFullDate(date);

  if (isSameDay(date, today)) {
    return 'Today • $fullDate';
  }

  if (isSameDay(date, yesterday)) {
    return 'Yesterday • $fullDate';
  }

  if (isSameDay(date, tomorrow)) {
    return 'Tomorrow • $fullDate';
  }

  return fullDate;
}

String formatFullDate(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final weekday = weekdays[date.weekday - 1];

  return '$weekday, '
      '${monthName(date.month)} '
      '${ordinal(date.day)}, '
      '${date.year}';
}

String monthName(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return months[month - 1];
}

String shortMonthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return months[month - 1];
}

String ordinal(int day) {
  if (day >= 11 && day <= 13) {
    return '${day}th';
  }

  switch (day % 10) {
    case 1:
      return '${day}st';
    case 2:
      return '${day}nd';
    case 3:
      return '${day}rd';
    default:
      return '${day}th';
  }
}

String formatCalendarTime(DateTime time) {
  final hour = time.hour == 0
      ? 12
      : time.hour > 12
      ? time.hour - 12
      : time.hour;

  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour >= 12 ? 'PM' : 'AM';

  return '$hour:$minute $period';
}

bool isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
