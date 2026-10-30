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
  final mqOverlay = MediaQuery.maybeOf(overlay.context);
  final mqCaller = MediaQuery.maybeOf(context);
  final topPadding = [
    mqOverlay?.viewPadding.top ?? 0.0,
    mqOverlay?.padding.top ?? 0.0,
    mqCaller?.viewPadding.top ?? 0.0,
    mqCaller?.padding.top ?? 0.0,
  ].reduce((a, b) => a > b ? a : b);
  final top = (topPadding > 30.0 ? topPadding : 44.0) + 20.0;

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
  if (error == null) return 'Something went wrong.';

  if (error is DioException) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Unable to reach the server. Please check your internet connection or server status.';
    }

    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    if (data is Map) {
      if (data['detail'] != null) {
        final detail = data['detail'].toString();
        if (detail.toLowerCase().contains('no active account') ||
            detail.toLowerCase().contains('credentials')) {
          return 'Invalid username/email or password. Please try again.';
        }
        return detail;
      }
      if (data['error'] != null) {
        return data['error'].toString();
      }
      if (data['message'] != null) {
        return data['message'].toString();
      }
      if (data['non_field_errors'] is List &&
          (data['non_field_errors'] as List).isNotEmpty) {
        return (data['non_field_errors'] as List).first.toString();
      }
      for (final entry in data.entries) {
        if (entry.value is List && (entry.value as List).isNotEmpty) {
          final first = (entry.value as List).first.toString();
          return '${entry.key}: $first';
        } else if (entry.value is String && (entry.value as String).isNotEmpty) {
          return '${entry.key}: ${entry.value}';
        }
      }
    } else if (data is String && data.trim().isNotEmpty) {
      final trimmed = data.trim();
      if (!trimmed.startsWith('<')) {
        return trimmed;
      }
    }

    if (statusCode == 401) {
      return 'Invalid username/email or password. Please try again.';
    }
    if (statusCode == 403) {
      return 'Access denied. You do not have permission.';
    }
    if (statusCode == 404) {
      return 'Requested resource not found.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'Server error ($statusCode). Please try again later.';
    }

    return 'Request failed. Please try again.';
  }

  final text = error.toString();
  if (text.contains('ApiException: 10') || text.contains('ApiException: 12500')) {
    return 'Google Sign-In needs setup: Register debug SHA-1 in Google Cloud Console OAuth Client IDs.';
  }
  if (text.contains('sign_in_failed')) {
    return 'Google Sign-In failed. Please verify your Google Play Services or network connection.';
  }
  if (text.contains('sign_in_canceled') || text.contains('canceled') || text.contains('cancelled')) {
    return 'Sign in was cancelled.';
  }
  if (text.contains('DioException') || text.contains('validateStatus')) {
    if (text.contains('401')) {
      return 'Invalid username or password. Please try again.';
    }
    if (text.contains('403')) {
      return 'Access denied.';
    }
    if (text.contains('404')) {
      return 'Requested service not found.';
    }
    return 'Unable to reach the server. Please try again later.';
  }
  if (text.startsWith('Exception: ')) {
    return text.substring(11);
  }
  return text;
}
