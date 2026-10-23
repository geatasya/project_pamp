import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/event_entity.dart';

const _loc = 'id_ID';

String formatShortRange(EventEntity e) {
  final s = e.date;
  final en = e.endDate;
  final full = DateFormat('dd MMM yyyy', _loc);
  if (en == null || DateUtils.isSameDay(s, en)) return full.format(s);
  if (s.year == en.year && s.month == en.month) {
    return '${DateFormat('dd', _loc).format(s)} - ${full.format(en)}';
  }
  if (s.year == en.year) {
    return '${DateFormat('dd MMM', _loc).format(s)} - ${full.format(en)}';
  }
  return '${full.format(s)} - ${full.format(en)}';
}

String formatLongRange(EventEntity e) {
  final s = e.date;
  final en = e.endDate;
  final full = DateFormat('d MMMM yyyy', _loc);
  if (en == null || DateUtils.isSameDay(s, en)) return full.format(s);
  if (s.year == en.year && s.month == en.month) {
    return '${s.day} - ${full.format(en)}';
  }
  if (s.year == en.year) {
    return '${DateFormat('d MMMM', _loc).format(s)} - ${full.format(en)}';
  }
  return '${full.format(s)} - ${full.format(en)}';
}

String formatRupiah(int v) =>
    NumberFormat.currency(locale: _loc, symbol: 'Rp ', decimalDigits: 0)
        .format(v);

String typeBadge(String t) {
  switch (t) {
    case 'Festival Musik':
      return 'FESTIVAL';
    case 'Konser Solo':
      return 'SOLO KONSER';
    case 'World Tour':
      return 'WORLD TOUR';
    default:
      return t.toUpperCase();
  }
}

/// "15:00 - 23:30 WIB (Pintu Buka: 14:00)" atau null kalau jam belum diisi.
String? timeText(EventEntity e) {
  if (e.startTime == null) return null;
  var t = e.endTime == null
      ? '${e.startTime} WIB'
      : '${e.startTime} - ${e.endTime} WIB';
  if (e.doorTime != null) t += ' (Pintu Buka: ${e.doorTime})';
  return t;
}

class CountdownInfo {
  final String label;
  final String shortLabel;
  final Color color;
  final Color textColor;
  const CountdownInfo(this.label, this.shortLabel, this.color, this.textColor);
}

CountdownInfo countdownOf(EventEntity e) {
  final now = DateTime.now();
  final today = DateTime.utc(now.year, now.month, now.day);
  final start = DateTime.utc(e.date.year, e.date.month, e.date.day);
  final end = DateTime.utc(e.lastDate.year, e.lastDate.month, e.lastDate.day);
  if (today.isAfter(end)) {
    return const CountdownInfo(
        'SUDAH LEWAT', 'Selesai', AppColors.subtle, AppColors.muted);
  }
  if (!today.isBefore(start)) {
    return const CountdownInfo('SEDANG BERLANGSUNG', 'Berlangsung',
        AppColors.greenBg, AppColors.green);
  }
  final d = start.difference(today).inDays;
  if (d == 1) {
    return const CountdownInfo(
        'BESOK', 'Besok', AppColors.amberBg, AppColors.amberText);
  }
  return CountdownInfo(
      '$d HARI LAGI', 'H-$d', AppColors.amberBg, AppColors.amberText);
}

class CountdownBadge extends StatelessWidget {
  final EventEntity event;
  final bool compact;
  const CountdownBadge({super.key, required this.event, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final c = countdownOf(event);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12, vertical: compact ? 5 : 6),
      decoration:
          BoxDecoration(color: c.color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        compact ? c.shortLabel : c.label,
        style: TextStyle(
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w800,
            color: c.textColor),
      ),
    );
  }
}
