import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();

  static Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Layanan lokasi perangkat belum aktif. Aktifkan GPS lalu coba lagi.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception(
        'Izin lokasi ditolak. Kamu tetap bisa mencari aktivitas berdasarkan kota.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw Exception(
        'Izin lokasi diblokir. Aktifkan izin lokasi Barengin melalui pengaturan perangkat.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }
}
