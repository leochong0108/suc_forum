class DateFormatter {
  static String formatFull(DateTime dt) {
    final now = DateTime.now();

    final months = [
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

    int hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    String amPm = dt.hour >= 12 ? 'pm' : 'am';
    String minute = dt.minute.toString().padLeft(2, '0');

    // 1. Check if the year is different from the current year
    String yearPart = dt.year != now.year ? ' ${dt.year}' : '';

    // 2. Combine into final format
    return '${dt.day} ${months[dt.month - 1]}$yearPart • $hour:$minute $amPm';
  }
}
