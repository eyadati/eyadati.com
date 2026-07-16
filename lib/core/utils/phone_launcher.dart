import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> launchPhoneUrl(String phone, BuildContext context) async {
  final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
  final uri = Uri.parse('tel:$cleaned');
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
  } catch (_) {}
  return false;
}
