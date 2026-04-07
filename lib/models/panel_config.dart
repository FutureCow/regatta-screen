// lib/models/panel_config.dart
import 'data_field.dart';

class PanelConfig {
  final int fieldCount;
  final List<DataField> fields;

  const PanelConfig({required this.fieldCount, required this.fields})
      : assert(fieldCount >= 1 && fieldCount <= 4),
        assert(fields.length == fieldCount);

  factory PanelConfig.defaults1() => PanelConfig(
        fieldCount: 2,
        fields: [DataField.speedGps, DataField.headingGps],
      );

  factory PanelConfig.defaults2() => PanelConfig(
        fieldCount: 1,
        fields: [DataField.raceTime],
      );

  Map<String, dynamic> toJson() => {
        'fieldCount': fieldCount,
        'fields': fields.map((f) => f.name).toList(),
      };

  factory PanelConfig.fromJson(Map<String, dynamic> json) => PanelConfig(
        fieldCount: json['fieldCount'] as int,
        fields: (json['fields'] as List)
            .map((f) => DataField.values.byName(f as String))
            .toList(),
      );

  PanelConfig copyWith({int? fieldCount, List<DataField>? fields}) =>
      PanelConfig(
        fieldCount: fieldCount ?? this.fieldCount,
        fields: fields ?? this.fields,
      );
}
