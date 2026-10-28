import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

const brandColor = Color(0xFFEC2F83);

String formatPrice(dynamic value) => value is num
    ? value.toStringAsFixed(2)
    : double.tryParse('$value')?.toStringAsFixed(2) ?? '0.00';

String friendlyError(Object? error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError)
      return 'Cannot reach the API at the configured address. Check that Django is running and that the phone/emulator can access your computer.';
    final detail = error.response?.data is Map
        ? (error.response!.data as Map)['detail']
        : null;
    if (detail != null) return detail.toString();
  }
  return error?.toString() ?? 'Something went wrong.';
}
