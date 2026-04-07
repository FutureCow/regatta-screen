// lib/screens/data_panel/data_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel_config.dart';
import '../../providers/settings_provider.dart';
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

    return Padding(
      padding: const EdgeInsets.all(12),
      child: _buildLayout(config),
    );
  }

  Widget _buildLayout(PanelConfig config) {
    switch (config.fieldCount) {
      case 1:
        return Center(
          child: DataFieldWidget(field: config.fields[0], fontSize: 72),
        );
      case 2:
        return Column(
          children: config.fields
              .map((f) => Expanded(
                    child: Center(
                      child: DataFieldWidget(field: f, fontSize: 48),
                    ),
                  ))
              .toList(),
        );
      case 3:
        return Column(
          children: config.fields
              .map((f) => Expanded(
                    child: Center(
                      child: DataFieldWidget(field: f, fontSize: 36),
                    ),
                  ))
              .toList(),
        );
      case 4:
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: config.fields
              .map((f) => Center(
                    child: DataFieldWidget(field: f, fontSize: 28),
                  ))
              .toList(),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
