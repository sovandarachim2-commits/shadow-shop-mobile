import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

const brandColor = Color(0xFFEC2F83);

void showStoreMessage(
  BuildContext context,
  String message, {
  required IconData icon,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        elevation: 8,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFF2E8ED)),
        ),
        content: Row(
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
          ],
        ),
      ),
    );
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
