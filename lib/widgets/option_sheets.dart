import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants.dart';
import '../core/controller.dart';
import '../theme/app_theme.dart';

/// Bottom sheet pilihan generik.
Future<T?> showPickerSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required T selected,
  required String Function(T option) label,
  String? Function(T option)? subtitle,
}) {
  final theme = Theme.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
          ),
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option == selected;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      selected: isSelected,
                      selectedTileColor: theme.colorScheme.primary.withValues(
                        alpha: 0.10,
                      ),
                      title: Text(
                        label(option),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      subtitle: subtitle?.call(option) == null
                          ? null
                          : Text(
                              subtitle!.call(option)!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(option),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Bottom sheet khusus pemilihan model Groq (bisa refresh dari API).
///
/// Paling atas ada opsi **Auto (muter)**: aplikasi merotasi model tiap
/// generate dan otomatis pindah ke model lain saat 429 / 5xx / error.
Future<void> showModelSheet(BuildContext context, AppController controller) {
  final theme = Theme.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
            ),
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(26),
            ),
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final isAuto = controller.settings.model == kAutoModelId;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Pilih model',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  controller.modelsError ?? 'Daftar diambil langsung dari akun Groq kamu',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: controller.modelsError != null
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Muat ulang',
                            onPressed: controller.isLoadingModels
                                ? null
                                : () => controller.refreshModels(),
                            icon: controller.isLoadingModels
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        children: <Widget>[
                          // ── Opsi Auto ──────────────────────────────
                          ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            selected: isAuto,
                            selectedTileColor: theme.colorScheme.primary
                                .withValues(alpha: 0.10),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: isAuto ? AppTheme.brand : null,
                                color: isAuto
                                    ? null
                                    : theme.colorScheme.primary.withValues(
                                        alpha: 0.10,
                                      ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.autorenew_rounded,
                                size: 20,
                                color: isAuto
                                    ? Colors.white
                                    : theme.colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              kAutoModelLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isAuto
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Rotasi model tiap generate + pindah otomatis '
                              'kalau model sibuk atau error',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            trailing: isAuto
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                            onTap: () async {
                              await controller.updateSettings(
                                controller.settings.copyWith(
                                  model: kAutoModelId,
                                ),
                              );
                              if (context.mounted) Navigator.of(context).pop();
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              'Atau pilih manual:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ),
                          // ── Daftar model ───────────────────────────
                          for (final model in controller.models)
                            ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              selected: model.id == controller.settings.model,
                              selectedTileColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.10),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.memory_rounded,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                model.label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight:
                                      model.id == controller.settings.model
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${model.id}${model.note.isEmpty ? '' : ' — ${model.note}'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              trailing: model.id == controller.settings.model
                                  ? Icon(
                                      Icons.check_circle_rounded,
                                      color: theme.colorScheme.primary,
                                    )
                                  : null,
                              onTap: () async {
                                await controller.updateSettings(
                                  controller.settings.copyWith(model: model.id),
                                );
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

/// Aksi berbagi teks.
Future<void> shareText(String text, {String subject = 'Hasil XyStudio AI'}) {
  return SharePlus.instance.share(ShareParams(text: text, subject: subject));
}
