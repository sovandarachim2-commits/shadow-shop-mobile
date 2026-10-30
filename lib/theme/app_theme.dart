import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

const brandColor = Color(0xFFEC2F83);

OverlayEntry? _storeMessageEntry;
Timer? _storeMessageTimer;

void dismissStoreMessage() {
  _storeMessageTimer?.cancel();
  _storeMessageTimer = null;
  if (_storeMessageEntry != null && _storeMessageEntry!.mounted) {
    _storeMessageEntry!.remove();
  }
  _storeMessageEntry = null;
}

void showStoreMessage(
  BuildContext context,
  String message, {
  required IconData icon,
}) {
  dismissStoreMessage();

  final overlay = Overlay.of(context, rootOverlay: true);
  final media = MediaQuery.of(context);
  final appBarHeight = Scaffold.maybeOf(context)?.appBarMaxHeight ?? 0;
  final top = media.padding.top + appBarHeight + 8;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) {
      return Positioned(
        top: top,
        left: 16,
        right: 16,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 220),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * -12),
              child: child,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF2E8ED)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(icon, color: brandColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Color(0xFF344054),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: dismissStoreMessage,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF98A2B3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
  _storeMessageEntry = entry;
  _storeMessageTimer = Timer(const Duration(seconds: 3), () {
    if (_storeMessageEntry == entry) {
      if (entry.mounted) {
        entry.remove();
      }
      _storeMessageEntry = null;
    }
  });
}

String formatPrice(dynamic value) => value is num
    ? value.toStringAsFixed(2)
    : double.tryParse('$value')?.toStringAsFixed(2) ?? '0.00';

String friendlyError(Object? error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Cannot reach the API at the configured address. Check that Django is running and that the phone/emulator can access your computer.';
    }
    final detail = error.response?.data is Map
        ? (error.response!.data as Map)['detail']
        : null;
    if (detail != null) return detail.toString();
  }
  return error?.toString() ?? 'Something went wrong.';
}
