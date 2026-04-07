// lib/screens/settings/panel_config_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/data_field.dart';
import '../../models/panel_config.dart';
import '../../providers/settings_provider.dart';

class PanelConfigScreen extends ConsumerStatefulWidget {
  final int panelIndex;
  const PanelConfigScreen({super.key, required this.panelIndex});

  @override
  ConsumerState<PanelConfigScreen> createState() => _PanelConfigScreenState();
}

class _PanelConfigScreenState extends ConsumerState<PanelConfigScreen> {
  late int _fieldCount;
  late List<DataField> _fields;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider).valueOrNull;
    final config = widget.panelIndex == 1
        ? (settings?.panel1 ?? PanelConfig.defaults1())
        : (settings?.panel2 ?? PanelConfig.defaults2());
    _fieldCount = config.fieldCount;
    _fields = List.from(config.fields);
    while (_fields.length < 4) {
      _fields.add(DataField.values
          .firstWhere((f) => !_fields.contains(f), orElse: () => DataField.speedGps));
    }
  }

  void _save() {
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings == null) return;
    final config = PanelConfig(
      fieldCount: _fieldCount,
      fields: _fields.take(_fieldCount).toList(),
    );
    final updated = widget.panelIndex == 1
        ? settings.copyWith(panel1: config)
        : settings.copyWith(panel2: config);
    ref.read(settingsProvider.notifier).save(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paneel ${widget.panelIndex} instellen'),
        actions: [TextButton(onPressed: _save, child: const Text('Opslaan'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Aantal velden'),
          const SizedBox(height: 8),
          Row(
            children: [1, 2, 3, 4].map((n) {
              final selected = _fieldCount == n;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _fieldCount = n),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$n',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ...List.generate(_fieldCount, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<DataField>(
                decoration: InputDecoration(
                  labelText: 'Veld ${i + 1}',
                  border: const OutlineInputBorder(),
                ),
                initialValue: _fields[i],
                items: DataField.values
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.label),
                        ))
                    .toList(),
                onChanged: (f) {
                  if (f != null) setState(() => _fields[i] = f);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
