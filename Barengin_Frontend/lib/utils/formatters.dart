import 'package:intl/intl.dart';

String formatRupiah(int amount) {
  if (amount <= 0) return 'Gratis';
  return 'Rp${NumberFormat('#,##0', 'id_ID').format(amount)}';
}

String formatDate(DateTime? date) {
  if (date == null) return 'Jadwal belum tersedia';
  return DateFormat('EEEE, d MMM', 'id_ID').format(date);
}

String formatTime(DateTime? date) {
  if (date == null) return '--.--';
  return DateFormat('HH.mm').format(date);
}

String formatSchedule(DateTime? start, DateTime? end) {
  if (start == null) return 'Jadwal belum tersedia';
  final day = DateFormat('EEE, d MMM', 'id_ID').format(start);
  final startTime = DateFormat('HH.mm').format(start);
  final endTime = end == null ? '' : '–${DateFormat('HH.mm').format(end)}';
  return '$day · $startTime$endTime';
}

String isoWithOffset(DateTime value) {
  final offset = value.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  final base = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(value);
  return '$base$sign$hours:$minutes';
}

String statusLabel(String status) {
  switch (status) {
    case 'published':
      return 'Published';
    case 'ongoing':
      return 'Sedang berlangsung';
    case 'completed':
      return 'Selesai';
    case 'cancelled':
      return 'Dibatalkan';
    case 'draft':
      return 'Draft';
    case 'pending':
      return 'Menunggu';
    case 'accepted':
      return 'Diterima';
    case 'rejected':
      return 'Ditolak';
    default:
      return status;
  }
}
