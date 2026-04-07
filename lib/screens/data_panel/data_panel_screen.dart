// lib/screens/data_panel/data_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/data_field.dart';
import '../../models/panel_config.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/tack_indicator.dart';
import 'data_field_widget.dart';

class DataPanelScreen extends ConsumerWidget {
  final int panelIndex; // 1 or 2

  const DataPanelScreen({super.key, required this.panelIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final config = panelIndex == 1
        ? (settings?.panel1 ?? PanelConfig.defaults1())
        : (settings?.panel2 ?? PanelConfig.defaults2());
    final showTack = panelIndex == 1
        ? (settings?.tackIndicatorPanel1 ?? false)
        : (settings?.tackIndicatorPanel2 ?? false);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 48,
        8,
        showTack ? 52 : 24,
      ),
      child: Stack(
        children: [
          _buildLayout(context, ref, config),
          if (showTack)
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: TackIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildLayout(BuildContext context, WidgetRef ref, PanelConfig config) {
    switch (config.fieldCount) {
      case 1:
        return _FieldCell(
          field: config.fields[0],
          panelIndex: panelIndex,
          fieldSlot: 0,
          config: config,
        );
      case 2:
        return Column(
          children: List.generate(
            2,
            (i) => Expanded(
              child: _FieldCell(
                field: config.fields[i],
                panelIndex: panelIndex,
                fieldSlot: i,
                config: config,
              ),
            ),
          ),
        );
      case 3:
        return Column(
          children: List.generate(
            3,
            (i) => Expanded(
              child: _FieldCell(
                field: config.fields[i],
                panelIndex: panelIndex,
                fieldSlot: i,
                config: config,
              ),
            ),
          ),
        );
      case 4:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _FieldCell(
                      field: config.fields[0],
                      panelIndex: panelIndex,
                      fieldSlot: 0,
                      config: config,
                    ),
                  ),
                  Expanded(
                    child: _FieldCell(
                      field: config.fields[1],
                      panelIndex: panelIndex,
                      fieldSlot: 1,
                      config: config,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _FieldCell(
                      field: config.fields[2],
                      panelIndex: panelIndex,
                      fieldSlot: 2,
                      config: config,
                    ),
                  ),
                  Expanded(
                    child: _FieldCell(
                      field: config.fields[3],
                      panelIndex: panelIndex,
                      fieldSlot: 3,
                      config: config,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _FieldCell extends ConsumerWidget {
  final DataField field;
  final int panelIndex;
  final int fieldSlot;
  final PanelConfig config;

  const _FieldCell({
    required this.field,
    required this.panelIndex,
    required this.fieldSlot,
    required this.config,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _pickField(context, ref),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor, width: 1),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fontSize = (constraints.maxHeight * 0.42).clamp(24.0, 160.0);
            return DataFieldWidget(field: field, fontSize: fontSize);
          },
        ),
      ),
    );
  }

  void _pickField(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Kies dataveld',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
          ),
          ...DataField.values.map(
            (f) => ListTile(
              title: Text(f.label),
              selected: f == field,
              onTap: () {
                final settings = ref.read(settingsProvider).valueOrNull;
                if (settings == null) return;
                final newFields = List<DataField>.from(config.fields);
                newFields[fieldSlot] = f;
                final newConfig = config.copyWith(fields: newFields);
                final updated = panelIndex == 1
                    ? settings.copyWith(panel1: newConfig)
                    : settings.copyWith(panel2: newConfig);
                ref.read(settingsProvider.notifier).save(updated);
                Navigator.pop(ctx);
              },
            ),
          ),
        ],
      ),
    );
  }
}
