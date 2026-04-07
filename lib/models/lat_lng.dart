// lib/models/lat_lng.dart
class LatLng {
  final double lat;
  final double lng;
  const LatLng(this.lat, this.lng);

  @override
  String toString() =>
      '${lat.toStringAsFixed(4)}°${lat >= 0 ? 'N' : 'S'} '
      '${lng.toStringAsFixed(4)}°${lng >= 0 ? 'E' : 'W'}';
}
