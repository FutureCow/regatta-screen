// lib/models/data_field.dart
enum DataField {
  speedGps,
  headingGps,
  headingMagnetic,
  raceTime,
  clockTime,
  countdown,
  distanceToLine,
  vmgToLine,
  latitude,
  longitude,
  windDirection,
}

extension DataFieldInfo on DataField {
  String get label => switch (this) {
        DataField.speedGps => 'Speed',
        DataField.headingGps => 'Koers GPS',
        DataField.headingMagnetic => 'Koers Mag',
        DataField.raceTime => 'Racetijd',
        DataField.clockTime => 'Tijd',
        DataField.countdown => 'Afteltimer',
        DataField.distanceToLine => 'Afstand lijn',
        DataField.vmgToLine => 'VMG',
        DataField.latitude => 'Breedtegraad',
        DataField.longitude => 'Lengtegraad',
        DataField.windDirection => 'Wind',
      };

  String get defaultUnit => switch (this) {
        DataField.speedGps => 'kts',
        DataField.headingGps ||
        DataField.headingMagnetic ||
        DataField.windDirection =>
          '°',
        DataField.distanceToLine || DataField.vmgToLine => 'm',
        _ => '',
      };
}
