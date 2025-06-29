import 'package:flutter/material.dart';

extension SnackbarContext on BuildContext {
  ScaffoldMessengerState successSnackbar(String text) =>
      ScaffoldMessenger.of(this)
        ..hideCurrentSnackBar()
        ..showSnackBar(_SnackbarsType.success(text));

  ScaffoldMessengerState errorSnackbar(String text, VoidCallback? onRetry) =>
      ScaffoldMessenger.of(this)
        ..hideCurrentSnackBar()
        ..showSnackBar(_SnackbarsType.error(text, onRetry));

  ScaffoldMessengerState undoSnackbar({
    required String text,
    required VoidCallback onUndo,
  }) =>
      ScaffoldMessenger.of(this)
        ..hideCurrentSnackBar()
        ..showSnackBar(_SnackbarsType.undo(text, onUndo));
}

class _SnackbarsType {
  const _SnackbarsType._();

  static SnackBar success(String text) =>
      _Snackbar.snackbar(text: text, icon: Icons.check);

  static SnackBar error(String text, VoidCallback? onRetry) =>
      _Snackbar.snackbar(
        text: text,
        icon: Icons.error_outline,
        action:
            onRetry != null
                ? SnackBarAction(
                  label: 'Retry',
                  onPressed: onRetry,
                  textColor: Colors.white,
                )
                : null,
      );

  static SnackBar undo(String text, VoidCallback onUndo) => _Snackbar.snackbar(
    text: text,
    action: SnackBarAction(
      label: 'Undo',
      onPressed: onUndo,
      textColor: Colors.white,
    ),
  );
}

class _Snackbar {
  const _Snackbar._();

  static SnackBar snackbar({
    required String text,
    IconData? icon,
    SnackBarAction? action,
  }) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(text)),
        ],
      ),
      action: action,
    );
  }
}
