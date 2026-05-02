import 'package:flutter/material.dart';

class ScanFoodFab extends StatelessWidget {
  const ScanFoodFab({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: const Icon(Icons.camera_alt_rounded),
      label: const Text('খাবার স্ক্যান করুন'),
    );
  }
}
