import 'package:flutter/material.dart';

/// Converts Pexels' "#63651C" style colour into a Flutter [Color].
/// Falls back to a neutral grey if the string is malformed.
Color colorFromHex(String hex, {Color fallback = const Color(0xFFCCCCCC)}) {
  final cleaned = hex.replaceFirst('#', '');
  if (cleaned.length != 6) return fallback;
  final value = int.tryParse('FF$cleaned', radix: 16);
  return value == null ? fallback : Color(value);
}